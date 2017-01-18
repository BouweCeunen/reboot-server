import System.IO
import Data.List
import Control.Exception
import System.Exit
import System.Environment
import System.Directory
import System.Process
import Data.Time
import Network.Socket (sendTo,defaultProtocol,inet_addr,socket,Family(AF_INET),SocketType(Datagram),SockAddr(SockAddrInet))
import Network


-- UDPSendPort = 1012
-- UDPSendIP = 127.0.0.1
-- port = ?

name = "RebootServer"
pass_msg = "password\r"
init_msg = "connect\r"

-- protocol 
--   init
--   'custom_name'
--   pass

-- it sends udp message to the UDPSendPort and UDPSendIP in case of incorrect protocol usage

-- just connect to reboot


check_pass :: String -> Bool
check_pass x
  | x == pass_msg = True
  | otherwise = False

check_init :: String -> Bool
check_init x
  | x == init_msg = True
  | otherwise = False
  

main :: IO ()
main = withSocketsDo $ do
    args <- getArgs
    case (length args) of
        3 -> do
            args <- System.Environment.getArgs
            path <- getCurrentDirectory
            let uDPSendPort = args !! 0
            let uDPSendIP = args !! 1
            let port = args !! 2 
            sock <- listenOn $ PortNumber (fromIntegral $ read port)
            reboot sock port (fromIntegral $ read uDPSendPort) uDPSendIP
        _ -> writeToStdOut "UDPSendPort UDPSendIP port" "ERROR args"

reboot :: Socket -> String -> PortNumber -> String -> IO ()
reboot sock port uDPSendPort uDPSendIP = do
    (h,ip,_) <- accept sock
    msg1 <- readMessage h "System" ip
    case check_init msg1 of
        True -> do
            msg2 <- readMessage h "System" ip
            msg3 <- readMessage h msg2 ip
            case check_pass msg3 of
                True -> do
                    writeToStdOut ("Accepted connection in " ++ name ++ " (" ++ port ++ "): " ++ msg2) ip
                    hClose h
                    exitCode <- system "sudo reboot"
                    let message = "REBOOT " ++ (show exitCode)
                    writeToStdOut message ip
                    reboot sock port uDPSendPort uDPSendIP
                False -> do
                    hClose h
                    let message =  "1" ++ "," ++ name ++ "," ++ port ++ "," ++ msg1 ++ " | " ++ msg2 ++ " | " ++ msg3
                    writeToStdOutSendUDP message ip uDPSendPort uDPSendIP
                    reboot sock port uDPSendPort uDPSendIP
        False -> do
            hClose h
            let message = "1" ++ "," ++ name ++ "," ++ port ++ "," ++ msg1 
            writeToStdOutSendUDP message ip uDPSendPort uDPSendIP
            reboot sock port uDPSendPort uDPSendIP


writeToStdOut :: String -> String -> IO ()
writeToStdOut msg ip = do
    time <- getZonedTime
    let message = "[" ++ (show time)  ++ "]" ++ "," ++ ip ++ "," ++ msg ++ "\n"
    putStr message
    hFlush stdout
    return ()

writeToStdOutSendUDP :: String -> String -> PortNumber -> String -> IO ()
writeToStdOutSendUDP msg ip uDPSendPort uDPSendIP = do
    time <- getZonedTime
    let message = "[" ++ (show time)  ++ "] " ++ ip ++ ": " ++ msg ++ "\n"
    putStr message
    hFlush stdout
    sendUDP message uDPSendIP uDPSendPort


readMessage :: Handle -> String -> String -> IO [Char]
readMessage h nameH ip = do
     result <- try (hGetLine h) :: IO (Either SomeException [Char])
     case result of
        Left ex -> do
             --putStr "error: "
             writeToStdOut (show ex) ip
             return ""
        Right msg -> do
             --putStr "message: "
             writeToStdOut ((show nameH) ++ ": " ++ msg) ip
             return msg

sendUDP :: String -> String -> PortNumber -> IO ()
sendUDP msg host port = withSocketsDo $ do
        s <- socket AF_INET Datagram defaultProtocol
        hostAddr <- inet_addr host
        Network.Socket.sendTo s msg (SockAddrInet port hostAddr)
        sClose s
        return ()

