{-# OPTIONS_GHC -Wunused-imports #-}

import Libra
  ( Choice (..),
    EnergyProfile (..),
    EnergyState (..),
    Level (..),
    Valence (..),
    Zone (..),
    parseChoice,
    showProfile,
    toZone,
  )
import Test.Hspec

main :: IO ()
main = hspec $ do
  describe "toZone" $ do
    it "positive x high is Performance" $
      toZone (EnergyState Positive High) `shouldBe` Performance

    it "negative x high is Survival" $
      toZone (EnergyState Negative High) `shouldBe` Survival

    it "negative x low is Burnout" $
      toZone (EnergyState Negative Low) `shouldBe` Burnout

    it "positive x low is Renewal" $
      toZone (EnergyState Positive Low) `shouldBe` Renewal

  describe "parseChoice" $ do
    it "parses l and r" $ do
      parseChoice "l" `shouldBe` Just L
      parseChoice "r" `shouldBe` Just R

    it "ignores surrounding whitespace" $
      parseChoice "  r  " `shouldBe` Just R

    it "rejects other input" $ do
      parseChoice "" `shouldBe` Nothing
      parseChoice "x" `shouldBe` Nothing
      parseChoice "l r" `shouldBe` Nothing

  describe "showProfile" $
    it "renders each energy as a markdown list item" $
      showProfile
        EnergyProfile
          { physical = EnergyState Positive High,
            emotional = EnergyState Positive Low,
            mental = EnergyState Negative High,
            spiritual = EnergyState Negative Low
          }
        `shouldBe` unlines
          [ "- 身体エネルギー: パフォーマンス活動ゾーン",
            "- 感情エネルギー: リニューアルゾーン",
            "- 思考エネルギー: サバイバルゾーン",
            "- 精神エネルギー: バーンアウトゾーン"
          ]
