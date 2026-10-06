import Text.Printf (printf)
import Data.List (foldl')
import Data.Word (Word64)
import Data.Bits (shiftR, xor)

-- splitmix64 による疑似乱数（外部ライブラリを使わないため自前で書く）
splitmix :: Word64 -> (Word64, Word64)
splitmix s = let s' = s + 0x9E3779B97F4A7C15
                 z1 = (s' `xor` (s' `shiftR` 30)) * 0xBF58476D1CE4E5B9
                 z2 = (z1 `xor` (z1 `shiftR` 27)) * 0x94D049BB133111EB
             in (z2 `xor` (z2 `shiftR` 31), s')

uniforms :: Int -> Word64 -> [Double]
uniforms 0 _ = []
uniforms n s = let (z, s') = splitmix s
               in (fromIntegral (z `shiftR` 11) / 9007199254740992) : uniforms (n-1) s'

-- モンテカルロの1シナリオの損益（裾の重い値と小さな値が混ざるようにする）
payoff :: Double -> Double
payoff u = if u > 0.999 then 1.0e8 * (u - 0.999) else u * 1.0e-3 - 5.0e-4

sumL :: [Double] -> Double
sumL = foldl' (+) 0

chunks :: Int -> [a] -> [[a]]
chunks k xs = let n = (length xs + k - 1) `div` k in go n xs
  where go _ [] = []
        go n ys = let (a, b) = splitAt n ys in a : go n b

kahan :: [Double] -> Double
kahan = fst . foldl' step (0, 0)
  where step (s, c) x = let y = x - c; t = s + y in (t, (t - s) - y)

main :: IO ()
main = do
  printf "(0.1 + 0.2) + 0.3 = %.17g\n" ((0.1 + 0.2) + 0.3 :: Double)
  printf "0.1 + (0.2 + 0.3) = %.17g\n" (0.1 + (0.2 + 0.3) :: Double)
  let n = 10000000
      xs = map payoff (uniforms n 20261002)
  printf "前から順に足す               : %.17g\n" (sumL xs)
  printf "後ろから順に足す             : %.17g\n" (sumL (reverse xs))
  printf "4つに分けて足し、結果を足す  : %.17g\n" (sumL (map sumL (chunks 4 xs)))
  printf "8つに分けて足し、結果を足す  : %.17g\n" (sumL (map sumL (chunks 8 xs)))
  printf "Kahan の補正つき加算         : %.17g\n" (kahan xs)
  printf "Kahan（後ろから）            : %.17g\n" (kahan (reverse xs))
