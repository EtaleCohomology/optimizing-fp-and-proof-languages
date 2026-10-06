{-# LANGUAGE ApplicativeDo #-}
import Control.Concurrent (forkIO, threadDelay)
import Control.Concurrent.MVar
import Text.Printf (printf)
import Bench

-- <*> の左右を、別々のスレッドで同時に実行する型
newtype Par a = Par { runPar :: IO a }
instance Functor Par where fmap f (Par x) = Par (fmap f x)
instance Applicative Par where
  pure = Par . pure
  Par mf <*> Par mx = Par $ do
    v <- newEmptyMVar
    _ <- forkIO (mf >>= putMVar v)   -- 左側を別のスレッドで始める
    x <- mx                           -- 右側をこのスレッドで実行する
    f <- takeMVar v                   -- 左側の終わりを待つ
    return (f x)
instance Monad Par where            -- >>= は、前の結果を待ってから次を始めるしかない
  Par m >>= k = Par (m >>= runPar . k)

-- 4つのセンサー。それぞれ 100 ミリ秒かかるとする
sensor :: Double -> Par Double
sensor v = Par (threadDelay 100000 >> return v)
camera, lidar, imu, gps :: Par Double
camera = sensor 1.0; lidar = sensor 2.0; imu = sensor 3.0; gps = sensor 4.0

fuse :: Double -> Double -> Double -> Double -> Double
fuse c l i g = (c + l + i + g) / 4

viaApplicative :: Par Double
viaApplicative = fuse <$> camera <*> lidar <*> imu <*> gps

viaMonad :: Par Double
viaMonad = camera >>= \c -> lidar >>= \l -> imu >>= \i -> gps >>= \g -> return (fuse c l i g)

-- ApplicativeDo：互いに依存しない do ブロックは、<*> に変換される
viaDo :: Par Double
viaDo = do
  c <- camera
  l <- lidar
  i <- imu
  g <- gps
  pure (fuse c l i g)

-- GPS の補正に IMU の値を使う（依存がある）場合
gpsCorrected :: Double -> Par Double
gpsCorrected i = Par (threadDelay 100000 >> return (4.0 + i * 0.001))

viaDoDependent :: Par Double
viaDoDependent = do
  c <- camera
  l <- lidar
  i <- imu
  g <- gpsCorrected i
  pure (fuse c l i g)

main :: IO ()
main = mapM_ run [ ("Applicative で書く", viaApplicative)
                 , ("Monad（>>=）で書く", viaMonad)
                 , ("do 記法（ApplicativeDo）、依存なし", viaDo)
                 , ("do 記法（ApplicativeDo）、GPS が IMU に依存", viaDoDependent) ]
  where run (name, p) = do
          (r, t) <- median5 (\_ -> runPar p)
          printf "%-42s %6.1f ms  結果 %.4f\n" name t r
