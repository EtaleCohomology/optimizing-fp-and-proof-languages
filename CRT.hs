import Text.Printf (printf)
import Data.Bits (testBit, shiftR)
import Control.Exception (evaluate)
import Bench

-- 繰り返し2乗法による、べき剰余（どちらの方法でも同じ関数を使う）
powMod :: Integer -> Integer -> Integer -> Integer
powMod b e m = go (b `mod` m) e 1
  where go _ 0 acc = acc
        go x k acc = go (x * x `mod` m) (k `shiftR` 1) (if testBit k 0 then acc * x `mod` m else acc)

-- ミラー–ラビン法（固定の底による確率的素数判定）
isProbablePrime :: Integer -> Bool
isProbablePrime n
  | n < 2 = False
  | even n = n == 2
  | otherwise = all witness [2,3,5,7,11,13,17,19,23,29,31,37,41,43,47,53]
  where
    (s, d) = split (n - 1) 0
    split m k = if even m then split (m `div` 2) (k + 1) else (k :: Int, m)
    witness a = let x = powMod a d n
                in x == 1 || x == n - 1 || any (== n - 1) (take (s - 1) (tail (iterate (\y -> y * y `mod` n) x)))

nextPrime :: Integer -> Integer
nextPrime n = head (filter isProbablePrime [n, n + 2 ..])

egcdInv :: Integer -> Integer -> Integer
egcdInv a m = let (_, x, _) = go a m in x `mod` m
  where go 0 b = (b, 0, 1)
        go x y = let (g, s, t) = go (y `mod` x) x in (g, t - (y `div` x) * s, s)

main :: IO ()
main = do
  let p = nextPrime (2 ^ 1023 + 1234567)            -- 1024 ビットの素数
      q = nextPrime (2 ^ 1023 + 98765432101)
      n = p * q
      e = 65537
      d = egcdInv e ((p - 1) * (q - 1))
      dp = d `mod` (p - 1); dq = d `mod` (q - 1)
      qinv = egcdInv q p
      msgs k = [ (k * 1000003 + i) * 7919 `mod` n | i <- [1 .. 20] ]
      cs k = map (\m -> powMod m e n) (msgs k)
      direct k = sum (map (\c -> powMod c d n) (cs k))
      viaCRT k = sum [ let m1 = powMod c dp p
                           m2 = powMod c dq q
                           h  = qinv * (m1 - m2) `mod` p
                       in m2 + h * q
                     | c <- cs k ]
  printf "法 n のビット数: %d\n" (length (takeWhile (> 0) (iterate (`div` 2) n)))
  (a, ta) <- median5 (\i -> evaluate (direct (fromIntegral i)))
  (b, tb) <- median5 (\i -> evaluate (viaCRT (fromIntegral i)))
  printf "法 n でそのまま計算（20回の復号）     : %.1f ms\n" ta
  printf "中国剰余定理で p と q に分けて計算    : %.1f ms\n" tb
  printf "結果の一致: %s  倍率: %.2f 倍\n" (show (a == b)) (ta / tb)
  printf "復号結果が元の平文と一致（i=1）: %s\n" (show (direct 1 == sum (msgs 1) && viaCRT 1 == sum (msgs 1)))
