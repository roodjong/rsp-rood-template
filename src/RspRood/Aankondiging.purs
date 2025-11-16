module RspRood.Aankondiging (main) where

import Prelude

import Data.Maybe (Maybe(..))
import Data.Number as Number
import Data.String (toUpper)
import Effect (Effect)
import Graphics.Canvas (Composite(..), getContext2D) as Canvas
import Graphics.Canvas (Dimensions, ScaleTransform, TextAlign(..), TextBaseline(..))
import Partial.Unsafe (unsafePartial)
import RspRood.Layer.TextBox (mkTextBoxLayer, textBoxTransform)
import RspRood.Layer.TextBox as TextBoxLayer
import Sjablong.Layer (mkSomeLayer)
import Sjablong.Layer as Layer
import Sjablong.Layer.Image (mkEmptyImageLayer, mkImageLayer)
import Sjablong.Layer.Image as ImageLayer
import Sjablong.Layer.Layers (mkSomeLayers)
import Sjablong.Layer.Rectangle (mkRectangleLayer)
import Sjablong.Layer.Ref (mkRefLayer)
import Sjablong.Layer.Ref as RefLayer
import Sjablong.Layer.Rotate (mkRotateLayer)
import Sjablong.Layer.Rotate as Rotate
import Sjablong.Layer.Text (TextLayer(..))
import Sjablong.Layer.Text as TextLayer
import Sjablong.Layer.Transform (mkTransformLayer)
import Sjablong.Layer.Undraggable (mkUndraggable, mkUndraggableHorizontal)
import Sjablong.Main (addEventListeners, connectCheckbox, connectCheckboxPure, connectObjectUrlInput, connectRange, connectScaleRange, connectSelect, connectTextArea, mkDownloadButton, mkTemplate, mkTemplateContext, redraw)

instagramDimensions :: Dimensions
instagramDimensions = { width: 1080.0, height: 1080.0 * 5.0 / 4.0 }

templateResolution :: Number
templateResolution = 2.0

templateResolutionScale :: ScaleTransform
templateResolutionScale = { scaleX: templateResolution, scaleY: templateResolution }

templateDimensions :: Dimensions
templateDimensions = { width: templateResolution, height: templateResolution } * instagramDimensions

templateWidth :: Number
templateWidth = templateDimensions.width

templateHeight :: Number
templateHeight = templateDimensions.height

main :: Effect Unit
main = void $ unsafePartial do
  Just templateContext <- mkTemplateContext "canvas" templateDimensions
  canvasContext <- Canvas.getContext2D templateContext.canvas

  imageLayer <- mkRefLayer =<< mkEmptyImageLayer { x: 0.0, y: 0.0 } { scaleX: 1.0, scaleY: 1.0 } Canvas.SourceOver
  connectObjectUrlInput templateContext "image" imageLayer ImageLayer.loadImage
  connectScaleRange templateContext "image-size" imageLayer

  let
    barHeight = 160.0 * templateResolution

  let
    logoScale = 0.07
    logos =
      { rsp:
          { width: 4960.0
          , height: 2469.0
          , variants: { red: "img/rsp/rsp_horizontaal_rood.png", white: "img/rsp/rsp_horizontaal_wit.png" }
          }
      , rood:
          { width: 2469.0
          , height: 2469.0
          , variants: { red: "img/rood/rood_rood.png", white: "img/rood/rood_wit.png" }
          }
      , rspRood:
          { width: 8000.0
          , height: 2469.0
          , variants: { red: "img/rsp-rood/rsp_rood_rood.png", white: "img/rsp-rood/rsp_rood_wit.png" }
          }
      }
  logoLayer <- mkRefLayer =<< mkImageLayer
    logos.rsp.variants.red
    { x: templateWidth - logos.rsp.width * logoScale - 32.0 * templateResolution
    , y: templateHeight - barHeight + (barHeight - logos.rsp.height * logoScale) / 2.0
    }
    { scaleX: logoScale, scaleY: logoScale }
    Canvas.SourceOver
  connectSelect templateContext "logo" logoLayer \name ->
    let
      logo = case name of
        "rsp" -> logos.rsp
        "rood" -> logos.rood
        "rsp-rood" -> logos.rspRood
        _ -> logos.rsp
      pos =
        { x: templateWidth - logo.width * logoScale - 32.0 * templateResolution
        , y: templateHeight - barHeight + (barHeight - logo.height * logoScale) / 2.0
        }
    in
      ImageLayer.loadImage logo.variants.red <<< ImageLayer.setPosition pos

  let
    textBoxPadding = { paddingX: 0.1, paddingY: 0.075 }
    textBoxShadowOffset = { offsetX: 0.15, offsetY: 0.15 }
    textBoxShadowOpacity = 0.4

  titleLayer <- mkRefLayer <=< mkTextBoxLayer "#c2000b" textBoxPadding textBoxShadowOffset textBoxShadowOpacity $ TextLayer
    { text: ""
    , lineHeight: 1.4
    , position: { x: templateWidth / 2.0, y: templateHeight - barHeight }
    , fillStyle: "#fff"
    , fontName: "Bebas Neue Pro"
    , fontStyle: "normal"
    , fontWeight: "bold"
    , fontSize: 100.0 * templateResolution
    , align: AlignCenter
    , baseline: BaselineBottom
    , letterSpacing: "0px"
    , dragOffset: Nothing
    , maxWidth: Just templateWidth
    , context: canvasContext
    }
  connectTextArea templateContext "title" titleLayer (TextBoxLayer.setText <<< toUpper)
  connectRange templateContext "title-size" titleLayer \size layer -> TextBoxLayer.setFontSize @Effect size layer
  connectCheckbox templateContext "title-shadow" titleLayer \shadow ->
    TextBoxLayer.setShadow textBoxShadowOffset (if shadow then textBoxShadowOpacity else 0.0)
  connectSelect templateContext "title-alignment" titleLayer \align ->
    TextBoxLayer.mapTextLayer $ TextLayer.setAlign $ case align of
      "left" -> AlignLeft
      "center" -> AlignCenter
      "right" -> AlignRight
      _ -> AlignCenter

  alignedTitleLayer <- mkRefLayer $ mkSomeLayer @Effect titleLayer
  connectSelect templateContext "title-alignment" alignedTitleLayer \align _ -> do
    { y } <- Layer.position titleLayer
    case align of
      "left" -> pure $ mkSomeLayer titleLayer
      "right" -> pure $ mkSomeLayer titleLayer
      "center-free" -> pure $ mkSomeLayer titleLayer
      "center" -> do
        RefLayer.modifyM_ (TextBoxLayer.mapTextLayer $ TextLayer.setPosition { x: templateWidth / 2.0, y }) titleLayer
        pure $ mkSomeLayer $ mkUndraggableHorizontal titleLayer
      _ -> pure $ mkSomeLayer titleLayer

  let
    textBoxRotationAngle = -3.0 * Number.pi / 180.0
  transformedTitleLayer <- mkRefLayer $ mkRotateLayer textBoxRotationAngle $ mkTransformLayer textBoxTransform alignedTitleLayer
  connectCheckboxPure templateContext "title-rotate" transformedTitleLayer \rotate ->
    Rotate.setAngle $ if rotate then textBoxRotationAngle else 0.0

  let
    layers = mkSomeLayers @Effect
      [ mkSomeLayer $ transformedTitleLayer
      , mkSomeLayer $ mkUndraggable logoLayer
      , mkSomeLayer $ mkUndraggable $ mkRectangleLayer { x: 0.0, y: templateHeight - barHeight, width: templateWidth, height: barHeight } "#fff"
      , mkSomeLayer imageLayer
      , mkSomeLayer $ mkUndraggable $ mkRectangleLayer { x: 0.0, y: 0.0, width: templateWidth, height: templateHeight } "#333"
      ]

  template <- mkTemplate templateContext layers
  redraw template
  addEventListeners template
  Just _ <- mkDownloadButton "download" "rsp-template.png" template
  pure unit
