{-# LANGUAGE DeriveFunctor #-}
import Text.Printf (printf)
import Data.List (foldl')
import Control.Exception (evaluate)
import Bench
import Data.Array (listArray, (!), Array)

-- Free モナド（外部ライブラリを使わず、自前で定義する）
data Free f a = Pure a | Free (f (Free f a)) deriving Functor
instance Functor f => Applicative (Free f) where
  pure = Pure
  Pure g <*> x = fmap g x
  Free fg <*> x = Free (fmap (<*> x) fg)
instance Functor f => Monad (Free f) where
  Pure a >>= k = k a
  Free m >>= k = Free (fmap (>>= k) m)
liftF :: Functor f => f a -> Free f a
liftF = Free . fmap Pure

-- 保険契約を記述する命令（構文）。意味（評価方法）はまだ与えない
data ContractF next
  = Premium Int Double next          -- 月 t に保険料を受け取る
  | Benefit Int Double next          -- 月 t に保険金を支払う
  | Survival Int (Double -> next)    -- 月 t までの生存確率を問い合わせる
  deriving Functor

premium t x = liftF (Premium t x ())
benefit t x = liftF (Benefit t x ())
survival t  = liftF (Survival t id)

-- 60年（720か月）の定期保険を1件、記述する
policy :: Double -> Free ContractF ()
policy age = mapM_ month [1 .. 720]
  where
    month t = do
      s <- survival t
      premium t (100 * s)
      s' <- survival (t + 1)
      benefit t (1.0e6 * (s - s'))

-- 1つ目の解釈：記述を、キャッシュフローの表に展開する（重い処理）
mortality :: Int -> Double
mortality t = exp (negate ((fromIntegral t / 1200) ** 1.3))

-- 生存確率を、ハザード率の数値積分で求める版（実務の射影に近い、重い計算）
mortalityHeavy :: Int -> Double
mortalityHeavy t = exp (negate (sum [ h (fromIntegral t * fromIntegral j / 200) | j <- [1 .. 200 :: Int] ] / 200))
  where h u = 0.0008 * exp (u / 300)

projectWith :: (Int -> Double) -> Free ContractF () -> [(Int, Double)]
projectWith _ (Pure ()) = []
projectWith m (Free (Premium t x k)) = (t, x) : projectWith m k
projectWith m (Free (Benefit t x k)) = (t, negate x) : projectWith m k
projectWith m (Free (Survival t k))  = projectWith m (k (m t))

-- 割引係数を先に表にしておく版（評価そのものは軽い）
dfTable :: Double -> Array Int Double
dfTable r = listArray (0, 722) [ 1 / (1 + r) ** (fromIntegral t / 12) | t <- [0 .. 722 :: Int] ]

pvFast :: Array Int Double -> [(Int, Double)] -> Double
pvFast df = foldl' (\acc (t, x) -> acc + x * df ! t) 0

valuationsFast :: [Array Int Double] -> [(Int, Double)] -> [Double]
valuationsFast [a, b, c, d] cf = [pvFast a cf, pvFast b cf * 1.05, pvFast c cf, pvFast d cf]

naiveB :: Int -> [Double]
naiveB k = let dfs = map dfTable [0.010, 0.008, 0.005, 0.000]
           in [ sum [ valuationsFast dfs (projectWith mortalityHeavy p) !! i | p <- portfolio k ] | i <- [0 .. 3] ]

sharedB :: Int -> [Double]
sharedB k = let dfs = map dfTable [0.010, 0.008, 0.005, 0.000]
                cfs = map (projectWith mortalityHeavy) (portfolio k)
            in [ sum [ valuationsFast dfs cf !! i | cf <- cfs ] | i <- [0 .. 3] ]

project :: Free ContractF () -> [(Int, Double)]
project (Pure ()) = []
project (Free (Premium t x k)) = (t, x) : project k
project (Free (Benefit t x k)) = (t, negate x) : project k
project (Free (Survival t k))  = project (k (mortality t))

-- 2つ目以降の解釈：キャッシュフローの表から、各評価を計算する（軽い処理）
pv :: Double -> [(Int, Double)] -> Double
pv r = foldl' (\acc (t, x) -> acc + x / (1 + r) ** (fromIntegral t / 12)) 0

valuations :: [(Int, Double)] -> [Double]
valuations cf = [ pv 0.010 cf          -- Pricing（価格付け）
                , pv 0.008 cf * 1.05   -- IFRS 17 風（リスク調整を上乗せ）
                , pv 0.005 cf          -- Solvency II 風（低い割引率）
                , pv 0.000 cf ]        -- ストレステスト（金利ゼロ）

portfolio :: Int -> [Free ContractF ()]
portfolio k = [ policy (30 + fromIntegral ((i + k) `mod` 30)) | i <- [1 .. 200 :: Int] ]

-- 共有しない：評価のたびに、記述を展開し直す
naive :: Int -> [Double]
naive k = [ sum [ v (project p) | p <- portfolio k ] | v <- [ (!! i) . valuations | i <- [0 .. 3] ] ]

-- 共有する：記述を1度だけ展開し、その結果を4つの評価で使い回す
shared :: Int -> [Double]
shared k = let cfs = map project (portfolio k)
         in [ sum [ valuations cf !! i | cf <- cfs ] | i <- [0 .. 3] ]

main :: IO ()
main = do
  (a, ta) <- median5 (\_ -> evaluate (sum (naive 0)))
  (b, tb) <- median5 (\_ -> evaluate (sum (shared 0)))
  printf "共有しない（評価ごとに展開）: %.1f ms  合計 %.6e\n" ta a
  printf "共有する（1度だけ展開）     : %.1f ms  合計 %.6e\n" tb b
  printf "倍率: %.2f 倍\n" (ta / tb)
  (c, tc) <- median5 (\_ -> evaluate (sum (naiveB 0)))
  (d, td) <- median5 (\_ -> evaluate (sum (sharedB 0)))
  printf "[射影が重く評価が軽い場合] 共有しない: %.1f ms  合計 %.6e\n" tc c
  printf "[射影が重く評価が軽い場合] 共有する  : %.1f ms  合計 %.6e\n" td d
  printf "倍率: %.2f 倍\n" (tc / td)
