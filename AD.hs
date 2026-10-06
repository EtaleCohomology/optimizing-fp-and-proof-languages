import Text.Printf (printf)

-- 双対数：値と微分係数の組
data Dual = Dual Double Double

instance Num Dual where
  Dual a a' + Dual b b' = Dual (a + b) (a' + b')
  Dual a a' * Dual b b' = Dual (a * b) (a' * b + a * b')    -- 積の微分法則
  negate (Dual a a') = Dual (negate a) (negate a')
  fromInteger n = Dual (fromInteger n) 0
  abs = undefined; signum = undefined
instance Fractional Dual where
  fromRational r = Dual (fromRational r) 0
  recip (Dual a a') = Dual (1 / a) (negate a' / (a * a))
instance Floating Dual where
  pi = Dual pi 0
  sin (Dual a a') = Dual (sin a) (cos a * a')               -- 連鎖律がここに入る
  cos (Dual a a') = Dual (cos a) (negate (sin a) * a')
  exp (Dual a a') = Dual (exp a) (exp a * a')
  log (Dual a a') = Dual (log a) (a' / a)
  asin = undefined; acos = undefined; atan = undefined
  sinh = undefined; cosh = undefined; asinh = undefined; acosh = undefined; atanh = undefined

diff :: (Dual -> Dual) -> Double -> Double
diff f x = let Dual _ d = f (Dual x 1) in d

main :: IO ()
main = do
  let f = \x -> sin (x * x)                 -- sin と「2乗」の合成
      x0 = 1.3
  printf "自動微分         : %.15f\n" (diff f x0)
  printf "手で微分した式   : %.15f\n" (2 * x0 * cos (x0 * x0))
  let g = \x -> exp (sin x) * log (1 + x * x)
  printf "自動微分         : %.15f\n" (diff g x0)
  printf "手で微分した式   : %.15f\n"
    (exp (sin x0) * cos x0 * log (1 + x0 * x0) + exp (sin x0) * (2 * x0 / (1 + x0 * x0)))
  -- 合成の微分は、微分の合成（関手性）
  let h1 = \x -> x * x; h2 = sin
  printf "diff (h2 . h1)            : %.15f\n" (diff (h2 . h1) x0)
  printf "diff h2 (h1 x) * diff h1 x: %.15f\n" (diff h2 (x0 * x0) * diff h1 x0)
