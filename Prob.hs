import Text.Printf (printf)
import Data.List (sortOn)
import qualified Data.Map.Strict as M

-- 確率分布のモナド：値と確率の組のリスト
newtype Dist a = Dist { runDist :: [(a, Rational)] }  -- 確率は有理数で厳密に持つ
instance Functor Dist where fmap f (Dist xs) = Dist [ (f a, p) | (a, p) <- xs ]
instance Applicative Dist where
  pure a = Dist [(a, 1)]
  Dist fs <*> Dist xs = Dist [ (f a, p * q) | (f, p) <- fs, (a, q) <- xs ]
instance Monad Dist where
  Dist xs >>= k = Dist [ (b, p * q) | (a, p) <- xs, (b, q) <- runDist (k a) ]

-- 1段目：市場の変動（ポートフォリオ価値の変化、単位は億円）
market :: Double -> Dist Double
market v = Dist [ (v * 1.05, 3/10), (v, 5/10), (v * 0.90, 15/100), (v * 0.70, 5/100) ]

-- 2段目：市場の状態に応じて、取引先が債務不履行になる確率が変わる（マルコフ核）
credit :: Double -> Dist Double
credit v = let pd = if v < 80 then 20/100 else 2/100
           in Dist [ (v, 1 - pd), (v - 15, pd) ]

-- 2つの段を、Kleisli 合成でつなぐ
scenario :: Double -> Dist Double
scenario = market >=> credit
  where (f >=> g) x = f x >>= g

-- 損失の分布から VaR と Expected Shortfall を求める
riskMeasures :: Rational -> Double -> Dist Double -> (Double, Double)
riskMeasures alpha v0 d =
  let losses = M.toList (M.fromListWith (+) [ (v0 - v, p) | (v, p) <- runDist d ])
      sorted = sortOn (negate . fst) losses              -- 損失の大きい順
      go acc [] = acc
      go (cum, xs) ((l, p) : rest)
        | cum >= 1 - alpha = (cum, xs)
        | otherwise = go (cum + p, (l, min p (1 - alpha - cum)) : xs) rest
      (_, tailPart) = go (0, []) sorted
      var = fst (head tailPart)
      es  = sum [ l * fromRational p | (l, p) <- tailPart ] / fromRational (1 - alpha)
  in (var, es)

main :: IO ()
main = do
  let d = scenario 100
  mapM_ (\(v, p) -> printf "価値 %6.1f  確率 %.4f\n" v (fromRational p :: Double))
        (M.toList (M.fromListWith (+) (runDist d)))
  printf "確率の合計: %s\n" (show (sum (map snd (runDist d))))
  let (var95, es95) = riskMeasures (95/100) 100 d
  printf "95%% VaR: %.2f 億円   95%% Expected Shortfall: %.2f 億円\n" var95 es95
