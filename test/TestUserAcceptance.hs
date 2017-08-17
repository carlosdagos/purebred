{-# LANGUAGE OverloadedStrings #-}
module TestUserAcceptance where

import Data.List (isInfixOf)
import Control.Monad (forM_)
import qualified Data.Text as T
import System.IO.Temp (withSystemTempDirectory)
import System.Directory (createDirectory, copyFile, listDirectory)
import Data.Ini (parseIni, writeIniFileWith, KeySeparator(..), WriteIniSettings(..))
import Data.Semigroup ((<>))
import GHC.MVar (MVar)
import Control.Concurrent (newEmptyMVar, forkIO, putMVar, takeMVar, killThread, threadDelay)
import Control.Exception (bracket)

import System.Process
       (shell, callProcess, readProcess, readCreateProcess, CreateProcess(..),
        CmdSpec(..), StdStream(..))
import System.Directory (getCurrentDirectory, removeFile)
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.Golden (goldenVsFile)

import Network.Socket hiding (recv)
import Network.Socket
       (bind, socket, Family(..), SocketType(..), defaultProtocol, SockAddr(..))
import Network.Socket.ByteString (recv)
import Data.ByteString.Char8 (pack, ByteString)

systemTests ::
  TestTree
systemTests = testGroup "result in the right state" [testMakesHardcopy]

testMakesHardcopy ::
  TestTree
testMakesHardcopy = goldenVsFile "does not crash" "test/data/test.golden" "/tmp/testoutput" smokeTest

smokeTest :: IO ()
smokeTest = do
  withSystemTempDirectory "purebredtest" $ \fp -> do
    testmdir <- prepareMaildir fp
    cfg <- prepareNotmuchCfg fp testmdir
    out <- prepareNotmuch cfg
    print out
    _ <- setUp testmdir
    callProcess "tmux" $ communicateSessionArgs ++ ["j", "j", "Enter"]
    out <- readProcess "tmux" hardcopyArgs []
    print out
    callProcess "tmux" $ savebufferArgs "/tmp/testoutput"
    teardown

waitReady :: MVar String -> IO ()
waitReady baton = do
    soc <- socket AF_UNIX Datagram defaultProtocol
    bind soc (SockAddrUnix "/tmp/purebred.socket")
    d <- recv soc 4096
    if d /= applicationReadySignal
        then error "application did not start up in time"
        else close soc >> removeFile "/tmp/purebred.socket" >> putMVar baton "ready"

applicationReadySignal :: ByteString
applicationReadySignal = pack "READY=1"

-- | setup the application in a tmux session
-- This is roughly how it goes:
-- * Fork a thread which sets up a socket. Wait for a connection, which sends us a READY signal
-- * In the mean time, start a tmux session in which we start purebred
-- * Press the "magic" key binding, which connects to our socket to signal purebred is up and running
-- * Our waiting thread receives the READY signal and we start testing
setUp :: FilePath -> IO (String)
setUp testmdir = do
    baton <- newEmptyMVar
    bracket
        (forkIO $ waitReady baton)
        killThread
        (const $
         callProcess "tmux" (tmuxSessionArgs testmdir) >>
         callProcess "tmux" (communicateSessionArgs ++ ["C-t"]) >>
         print "Waiting for startup" >>
         takeMVar baton)

tmuxSessionArgs :: FilePath -> [String]
tmuxSessionArgs cfg =
    [ "new-session"
    , "-x"
    , "95"
    , "-y"
    , "56"
    , "-d"
    , "-s"
    , "purebredtest"
    , "-n"
    , "purebred"
    , "purebred"
    , "--database"
    , cfg]

communicateSessionArgs :: [String]
communicateSessionArgs = words "send-keys -t purebredtest"

hardcopyArgs :: [String]
hardcopyArgs = words "capture-pane -p -t purebredtest:purebred"

savebufferArgs :: FilePath -> [String]
savebufferArgs hardcopypath =
    ["save-buffer", "-b", "purebredcapture", hardcopypath]

checkSessionStarted :: IO ()
checkSessionStarted = do
    out <- readProcess "tmux" ["list-sessions"] []
    print out
    if "purebredtest" `isInfixOf` out
        then pure ()
        else error "no session created"

teardown :: IO ()
teardown = do
  -- quit the application
  callProcess "tmux" $ communicateSessionArgs ++ (words "Esc Enter")
  -- XXX make sure it's dead
  callProcess "tmux" $ words "unlink-window -k -t purebredtest"

prepareNotmuch :: FilePath -> IO (String)
prepareNotmuch notmuchcfg = do
    readProcess "notmuch" ["--config=" <> notmuchcfg, "new"] []

-- | produces a notmuch config, which points to our local maildir
-- XXX this will crash if the ini file can not be parsed
prepareNotmuchCfg :: FilePath -> FilePath -> IO (FilePath)
prepareNotmuchCfg testdir testmdir = do
  let (Right ini) = parseIni (T.pack "[database]\npath=" <> T.pack testmdir)
  let nmcfg = testdir <> "/notmuch-config"
  writeIniFileWith (WriteIniSettings EqualsKeySeparator) nmcfg ini
  pure nmcfg

prepareMaildir :: FilePath -> IO (FilePath)
prepareMaildir testdir = do
  let testmdir = testdir <> "/Maildir/"
  c <- getCurrentDirectory
  let maildir = c <> "/test/data/Maildir/"
  callProcess "cp" ["-r", maildir, testmdir]
  pure testmdir