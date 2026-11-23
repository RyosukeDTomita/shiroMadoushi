{-# OPTIONS_GHC -Wunused-imports #-}

module Main (main) where

import Libra
  ( Choice (..),
    EnergyKind (..),
    EnergyProfile (..),
    EnergyState (..),
    Level (..),
    Valence (..),
    kindLabel,
    parseChoice,
    showProfile,
  )
import System.IO (hFlush, stdout)

-- | 2択の質問をする。l なら左の選択肢、r なら右の選択肢を返す。
-- l / r 以外が入力されたら同じ質問をもう一度出す。
askChoice :: String -> (String, a) -> (String, a) -> IO a
askChoice question (leftName, leftValue) (rightName, rightValue) = do
  putStr $ question ++ ": " ++ leftName ++ " or " ++ rightName ++ "? (l/r) "
  hFlush stdout
  input <- getLine
  case parseChoice input of
    Just L -> pure leftValue
    Just R -> pure rightValue
    Nothing -> do
      putStrLn "l か r で答えてください"
      askChoice question (leftName, leftValue) (rightName, rightValue)

-- | 1種類のエネルギーについて気持ちとエネルギー量を質問する
askState :: EnergyKind -> IO EnergyState
askState k = do
  let prefix = kindLabel k ++ "状態: "
  v <- askChoice (prefix ++ "Valence") ("positive", Positive) ("negative", Negative)
  l <- askChoice (prefix ++ "Energy") ("high", High) ("low", Low)
  pure $ EnergyState v l

-- | 4種類のエネルギーについて質問してプロファイルを作る (計8問)
askProfile :: IO EnergyProfile
askProfile = do
  ph <- askState Physical
  em <- askState Emotional
  me <- askState Mental
  sp <- askState Spiritual
  pure $
    EnergyProfile
      { physical = ph,
        emotional = em,
        mental = me,
        spiritual = sp
      }

main :: IO ()
main = do
  todayProfile <- askProfile
  putStr $ showProfile todayProfile
