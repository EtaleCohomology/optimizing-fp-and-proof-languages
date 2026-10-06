module Bench (timeMs, median5) where
import GHC.Clock (getMonotonicTimeNSec)
import Data.List (sort)
import Control.Exception (evaluate)

timeMs :: IO a -> IO (a, Double)
timeMs act = do
  t0 <- getMonotonicTimeNSec
  r <- act
  t1 <- getMonotonicTimeNSec
  return (r, fromIntegral (t1 - t0) / 1e6)

median5 :: (Int -> IO a) -> IO (a, Double)
median5 mk = do
  rs <- mapM (\i -> timeMs (mk i)) [1..5]
  let ts = sort (map snd rs)
  return (fst (head rs), ts !! 2)
