{-# OPTIONS_GHC -Wunused-imports #-}

-- | 人間の4つのエネルギーとゾーンを扱う純粋なロジック。IO は app/Main.hs 側に寄せる。
module Libra
  ( EnergyKind (..),
    Zone (..),
    EnergyState (..),
    Valence (..),
    Level (..),
    EnergyProfile (..),
    toZone,
    stateOf,
    zones,
    kindLabel,
    showZone,
    showProfile,
    Choice (..),
    parseChoice,
  )
where

-- | 人間の4つのエネルギー
data EnergyKind
  = -- | 身体
    Physical
  | -- | 感情
    Emotional
  | -- | 思考
    Mental
  | -- | 精神
    Spiritual
  deriving (Show, Eq, Enum, Bounded)

-- | エネルギーの状態から決まるゾーン
data Zone
  = -- | パフォーマンス活動ゾーン: ポジティブ × エネルギーあり
    Performance
  | -- | サバイバルゾーン: ネガティブ × エネルギーあり
    Survival
  | -- | バーンアウトゾーン: ネガティブ × エネルギーなし
    Burnout
  | -- | リニューアルゾーン: ポジティブ × エネルギーなし
    Renewal
  deriving (Show, Eq, Enum, Bounded)

-- | 1種類のエネルギーの状態
data EnergyState = EnergyState
  { valence :: Valence,
    level :: Level
  }
  deriving (Show, Eq)

-- | 気持ち
data Valence = Positive | Negative
  deriving (Show, Eq, Enum, Bounded)

-- | エネルギーが高いか低いか (エネルギーあり / なし)
data Level = High | Low
  deriving (Show, Eq, Enum, Bounded)

-- | エネルギーの状態からゾーンを決める
toZone :: EnergyState -> Zone
toZone (EnergyState Positive High) = Performance
toZone (EnergyState Negative High) = Survival
toZone (EnergyState Negative Low) = Burnout
toZone (EnergyState Positive Low) = Renewal

-- | 4種類のエネルギーそれぞれの状態
data EnergyProfile = EnergyProfile
  { physical :: EnergyState,
    emotional :: EnergyState,
    mental :: EnergyState,
    spiritual :: EnergyState
  }
  deriving (Show, Eq)

-- | 指定した種類のエネルギーの状態を取り出す
stateOf :: EnergyKind -> EnergyProfile -> EnergyState
stateOf Physical p = physical p
stateOf Emotional p = emotional p
stateOf Mental p = mental p
stateOf Spiritual p = spiritual p

-- | 各エネルギーがどのゾーンにいるか
zones :: EnergyProfile -> [(EnergyKind, Zone)]
zones p = [(k, toZone $ stateOf k p) | k <- [minBound .. maxBound]]

-- | 表示用の日本語ラベル (表示と質問の両方で使う)
kindLabel :: EnergyKind -> String
kindLabel Physical = "身体"
kindLabel Emotional = "感情"
kindLabel Mental = "思考"
kindLabel Spiritual = "精神"

-- | 1行分を Markdown のリスト形式で表示する
showZone :: (EnergyKind, Zone) -> String
showZone (k, z) = "- " ++ kindLabel k ++ "エネルギー: " ++ zoneLabel z
  where
    zoneLabel :: Zone -> String
    zoneLabel Performance = "パフォーマンス活動ゾーン"
    zoneLabel Survival = "サバイバルゾーン"
    zoneLabel Burnout = "バーンアウトゾーン"
    zoneLabel Renewal = "リニューアルゾーン"

-- | プロファイル全体を表示用の文字列にする
showProfile :: EnergyProfile -> String
showProfile p = unlines [showZone kz | kz <- zones p]

-- | l / r の回答
data Choice = L | R
  deriving (Show, Eq)

-- | 入力文字列を回答に変換する (前後の空白は無視)
parseChoice :: String -> Maybe Choice
parseChoice input = case words input of
  ["l"] -> Just L
  ["r"] -> Just R
  _ -> Nothing
