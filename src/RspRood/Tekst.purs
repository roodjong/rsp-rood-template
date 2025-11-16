module RspRood.Tekst (main) where

import Prelude

import Data.Maybe (Maybe(..))
import Data.Number as Number
import Data.String (toUpper)
import Effect (Effect)
import Effect.Ref as Ref
import Graphics.Canvas (Composite(..), addColorStop, createLinearGradient, getContext2D) as Canvas
import Graphics.Canvas (Dimensions, ScaleTransform, TextAlign(..), TextBaseline(..))
import Parsing.String.Basic (letter)
import Partial.Unsafe (unsafePartial)
import RspRood.Layer.TextBox (mkTextBoxLayer, textBoxTransform)
import RspRood.Layer.TextBox as TextBoxLayer
import Sjablong.Layer (mkSomeLayer)
import Sjablong.Layer as Layer
import Sjablong.Layer.Image (mkEmptyImageLayer, mkImageLayer)
import Sjablong.Layer.Image as ImageLayer
import Sjablong.Layer.Layers (mkSomeLayers)
import Sjablong.Layer.Path (FillStyle(..), PathLayer(..))
import Sjablong.Layer.Rectangle (mkRectangleLayer)
import Sjablong.Layer.Rectangle as RectangleLayer
import Sjablong.Layer.Ref (mkRefLayer)
import Sjablong.Layer.Ref as RefLayer
import Sjablong.Layer.Rotate (mkRotateLayer)
import Sjablong.Layer.Rotate as Rotate
import Sjablong.Layer.Text (TextLayer(..))
import Sjablong.Layer.Text as TextLayer
import Sjablong.Layer.Text.Markup (MarkupTextLayer(..))
import Sjablong.Layer.Text.Markup as MarkupTextLayer
import Sjablong.Layer.Transform (mkTransformLayer)
import Sjablong.Layer.Undraggable (mkUndraggable, mkUndraggableHorizontal)
import Sjablong.Main (addEventListeners, connectCheckbox, connectCheckboxPure, connectInputPure, connectObjectUrlInput, connectRange, connectScaleRange, connectSelect, connectTextArea, connectTextAreaPure, listenSelect, mkDownloadButton, mkTemplate, mkTemplateContext, redraw)

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

  backgroundLayer <- mkRefLayer $ mkRectangleLayer
    { x: 0.0
    , y: 0.0
    , width: templateWidth
    , height: templateHeight
    }
    "#fff"

  let
    colorSchemes =
      { whiteRed:
          { title: "#fff"
          , titleBackground: "#c2000b"
          , background: "#fff"
          , bodyText: "#000"
          , logo: _.red
          }
      , redWhite:
          { title: "#C2000B"
          , titleBackground: "white"
          , background: "#C2000B"
          , bodyText: "white"
          , logo: _.white
          }
      , paleRedWhite:
          { title: "#973936"
          , titleBackground: "white"
          , background: "#973936"
          , bodyText: "white"
          , logo: _.white
          }
      , greyWhite:
          { title: "#222222"
          , titleBackground: "white"
          , background: "#222222"
          , bodyText: "white"
          , logo: _.white
          }
      , blackWhite:
          { title: "black"
          , titleBackground: "white"
          , background: "black"
          , bodyText: "white"
          , logo: _.white
          }
      , natoBlueWhite:
          { title: "#003161"
          , titleBackground: "white"
          , background: "#003161"
          , bodyText: "white"
          , logo: _.white
          }
      , climateGreenWhite:
          { title: "#51824f"
          , titleBackground: "white"
          , background: "#51824f"
          , bodyText: "white"
          , logo: _.white
          }
      , purpleWhite:
          { title: "#716185"
          , titleBackground: "white"
          , background: "#716185"
          , bodyText: "white"
          , logo: _.white
          }
      }

  colorScheme <- Ref.new colorSchemes.whiteRed
  let
    setColorScheme name = flip Ref.modify colorScheme $ const $ case name of
      "white-red" -> colorSchemes.whiteRed
      "pale-red-white" -> colorSchemes.paleRedWhite
      "red-white" -> colorSchemes.redWhite
      "grey-white" -> colorSchemes.greyWhite
      "black-white" -> colorSchemes.blackWhite
      "NATO-blue-white" -> colorSchemes.natoBlueWhite
      "climate-green-white" -> colorSchemes.climateGreenWhite
      "purple-white" -> colorSchemes.purpleWhite
      _ -> colorSchemes.whiteRed

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
    , y: templateHeight - logos.rsp.height * logoScale - 32.0 * templateResolution
    }
    { scaleX: logoScale, scaleY: logoScale }
    Canvas.SourceOver

  let
    setLogo getLogo getVariant = do
      let
        logo = getLogo logos
        logoVariant = getVariant logo.variants
        pos =
          { x: templateWidth - logo.width * logoScale - 32.0 * templateResolution
          , y: templateHeight - logo.height * logoScale - 32.0 * templateResolution
          }
      RefLayer.modifyM (ImageLayer.loadImage @Effect logoVariant <<< ImageLayer.setPosition pos) logoLayer

  logo <- Ref.new _.rsp
  listenSelect templateContext "logo" \name -> void do
    getLogo <- flip Ref.modify logo $ const case name of
        "rsp" -> _.rsp
        "rood" -> _.rood
        "rsp-rood" -> _.rspRood
        _ -> _.rsp
    getVariant <- Ref.read colorScheme <#> _.logo
    setLogo getLogo getVariant

  let
    textBoxPadding = { paddingX: 0.1, paddingY: 0.075 }
    textBoxShadowOffset = { offsetX: 0.15, offsetY: 0.15 }
    textBoxShadowOpacity = 0.4

  titleLayer <- mkRefLayer <=< mkTextBoxLayer "#c2000b" textBoxPadding textBoxShadowOffset textBoxShadowOpacity $ TextLayer
    { text: ""
    , lineHeight: 1.4
    , position: { x: templateWidth / 2.0, y: 150.0 * templateResolution }
    , fillStyle: "#fff"
    , fontName: "Bebas Neue Pro"
    , fontStyle: "normal"
    , fontWeight: "bold"
    , fontSize: 100.0 * templateResolution
    , align: AlignCenter
    , baseline: BaselineTop
    , letterSpacing: "0px"
    , dragOffset: Nothing
    , maxWidth: Just $ templateWidth - 64.0 * templateResolution
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
      "center" -> do
        RefLayer.modifyM_ (TextBoxLayer.mapTextLayer $ TextLayer.setPosition { x: templateWidth / 2.0, y }) titleLayer
        pure $ mkSomeLayer $ mkUndraggableHorizontal titleLayer
      _ -> do
        RefLayer.modifyM_ (TextBoxLayer.mapTextLayer $ TextLayer.setPosition { x: templateWidth / 2.0, y }) titleLayer
        pure $ mkSomeLayer $ mkUndraggableHorizontal titleLayer

  let
    textBoxRotationAngle = -3.0 * Number.pi / 180.0
  transformedTitleLayer <- mkRefLayer $ mkRotateLayer textBoxRotationAngle $ mkTransformLayer textBoxTransform alignedTitleLayer
  connectCheckboxPure templateContext "title-rotate" transformedTitleLayer \rotate ->
    Rotate.setAngle $ if rotate then textBoxRotationAngle else 0.0

  bodyTextLayer <- mkRefLayer $ MarkupTextLayer
    { text: []
    , lineHeight: 1.5
    , position: { x: 64.0 * templateResolution, y: 300.0 * templateResolution }
    , maxWidth: Just $ templateWidth - 2.0 * 64.0 * templateResolution
    , fillStyle: "#000"
    , font:
        { name: "Bebas Neue Pro"
        , style: { normal: "normal", italic: "italic" }
        , weight: { normal: "normal", bold: "bold" }
        , size: 45.0 * templateResolution
        }
    , align: AlignLeft
    , baseline: BaselineTop
    , letterSpacing: "0px"
    , emptyLineHeight: 0.5
    , dragOffset: Nothing
    , context: canvasContext
    }
  connectTextAreaPure templateContext "bodytext" bodyTextLayer MarkupTextLayer.setText'

  listenSelect templateContext "color-scheme" \name -> void do
    cs <- setColorScheme name

    RefLayer.modify_ (RectangleLayer.setFillStyle cs.background) backgroundLayer
    RefLayer.modify_ (MarkupTextLayer.setFillStyle cs.bodyText) bodyTextLayer

    getLogo <- Ref.read logo
    let getVariant = cs.logo
    void $ setLogo getLogo getVariant

    RefLayer.modifyM_ (TextBoxLayer.mapTextLayer (TextLayer.setFillStyle cs.title) <=< TextBoxLayer.setFillStyle cs.titleBackground) titleLayer

  let
    layers = mkSomeLayers @Effect
      [ mkSomeLayer $ transformedTitleLayer
      , mkSomeLayer $ mkUndraggableHorizontal bodyTextLayer
      , mkSomeLayer $ mkUndraggable logoLayer
      , mkSomeLayer $ mkUndraggable backgroundLayer
      ]

  template <- mkTemplate templateContext layers
  redraw template
  addEventListeners template
  Just _ <- mkDownloadButton "download" "rsp-template.png" template
  pure unit
