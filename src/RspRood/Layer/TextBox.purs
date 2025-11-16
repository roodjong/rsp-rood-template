module RspRood.Layer.TextBox
  ( TextBoxLayer(..)
  , mkTextBoxLayer
  , modifyTextLayer
  , mapTextLayer
  , setText
  , setFontSize
  , setFillStyle
  , setShadow
  , Padding(..)
  , textBoxTransform
  ) where

import Prelude

import Effect.Class (class MonadEffect, liftEffect)
import Graphics.Canvas (Transform)
import Sjablong.Layer (class Layer, containsPoint, drag, dragEnd, dragStart, draw, position, translate)
import Sjablong.Layer.Group (Group, mkGroup)
import Sjablong.Layer.Rectangle (RectangleLayer, mkRectangleLayer)
import Sjablong.Layer.Text (TextLayer(..), layoutText)
import Sjablong.Layer.Text as TextLayer
import Sjablong.Layer.Tuple (TupleLayer, fstLayer, mkTupleLayer)

textBoxTransform :: Transform
textBoxTransform = { a: 1.0, b: 0.0, c: -0.1, d: 1.0, e: 120.0, f: 0.0 }

type Padding = { paddingX :: Number, paddingY :: Number }

newtype TextBoxLayer = TextBoxLayer
  { layer :: TupleLayer TextLayer (Group RectangleLayer)
  , fillStyle :: String
  , padding :: Padding
  , shadow ::
      { offset :: { offsetX :: Number, offsetY :: Number }
      , opacity :: Number
      }
  }

mkTextBoxLayer
  :: forall @m
   . MonadEffect m
  => String -- ^ fill style of background rectangles
  -> Padding -- ^ background rectangle padding, fraction of font size
  -> { offsetX :: Number, offsetY :: Number } -- ^ shadow offset
  -> Number -- ^ shadow opacity
  -> TextLayer
  -> m TextBoxLayer
mkTextBoxLayer fillStyle padding@{ paddingX, paddingY } shadowOffset shadowOpacity textLayer@(TextLayer tl) = do
  { lines, lineHeight } <- liftEffect $ layoutText textLayer
  let
    lineToRectangle { position: { x, y }, width } = mkRectangleLayer
      { x: x - paddingX * tl.fontSize
      , y: y - paddingY * tl.fontSize
      , width: width + 2.0 * paddingX * tl.fontSize
      , height: lineHeight + 2.0 * paddingY * tl.fontSize
      }
      fillStyle
    lineToShadow { position: { x, y }, width } = mkRectangleLayer
      { x: x - (paddingX - shadowOffset.offsetX) * tl.fontSize
      , y: y - (paddingY - shadowOffset.offsetY) * tl.fontSize
      , width: width + 2.0 * paddingX * tl.fontSize
      , height: lineHeight + 2.0 * paddingY * tl.fontSize
      }
      ("rgba(0,0,0," <> show shadowOpacity <> ")")
    rectangleLayers = map lineToRectangle lines
    shadowLayers = map lineToShadow lines
    layer = mkTupleLayer textLayer $ mkGroup $ rectangleLayers <> shadowLayers
  pure $ TextBoxLayer
    { layer
    , fillStyle
    , padding
    , shadow:
        { offset: shadowOffset
        , opacity: shadowOpacity
        }
    }

modifyTextLayer :: forall @m. MonadEffect m => (TextLayer -> m TextLayer) -> TextBoxLayer -> m TextBoxLayer
modifyTextLayer f (TextBoxLayer l) =
  mkTextBoxLayer l.fillStyle l.padding l.shadow.offset l.shadow.opacity =<< f (fstLayer l.layer)

mapTextLayer :: forall @m. MonadEffect m => (TextLayer -> TextLayer) -> TextBoxLayer -> m TextBoxLayer
mapTextLayer f = modifyTextLayer (pure <<< f)

setText :: forall @m. MonadEffect m => String -> TextBoxLayer -> m TextBoxLayer
setText = mapTextLayer <<< TextLayer.setText

setFontSize :: forall @m. MonadEffect m => Number -> TextBoxLayer -> m TextBoxLayer
setFontSize = mapTextLayer <<< TextLayer.setFontSize

setFillStyle :: forall @m. MonadEffect m => String -> TextBoxLayer -> m TextBoxLayer
setFillStyle fillStyle (TextBoxLayer l) =
  mkTextBoxLayer fillStyle l.padding l.shadow.offset l.shadow.opacity $ fstLayer l.layer

setShadow
  :: forall @m
   . MonadEffect m
  => { offsetX :: Number, offsetY :: Number } -- ^ shadow offset
  -> Number -- ^ shadow opacity
  -> TextBoxLayer
  -> m TextBoxLayer
setShadow shadowOffset shadowOpacity (TextBoxLayer l) =
  mkTextBoxLayer l.fillStyle l.padding shadowOffset shadowOpacity $ fstLayer l.layer

instance (Monad m, MonadEffect m) => Layer m TextBoxLayer where
  position (TextBoxLayer l) = position l.layer
  translate translation (TextBoxLayer l) = translate translation l.layer <#> \layer -> TextBoxLayer l { layer = layer }
  containsPoint p (TextBoxLayer l) = containsPoint p l.layer
  dragStart drag (TextBoxLayer l) = dragStart drag l.layer <#> \layer -> TextBoxLayer l { layer = layer }
  drag translation (TextBoxLayer l) = drag translation l.layer <#> \layer -> TextBoxLayer l { layer = layer }
  dragEnd (TextBoxLayer l) = dragEnd l.layer <#> \layer -> TextBoxLayer l { layer = layer }

  draw ctx (TextBoxLayer l) = draw @m ctx l.layer
