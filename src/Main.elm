module Main exposing (main)

import Css exposing (rem, zero)
import Css.Global
import Document exposing (Document)
import Head
import Head.Seo as Seo
import Html as PlainHtml
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes exposing (css)
import Markup
import Metadata exposing (Metadata)
import Pages exposing (PathKey, images, pages)
import Pages.Manifest as Manifest
import Pages.Manifest.Category
import Pages.PagePath exposing (PagePath)
import Pages.Platform
import Pages.StaticHttp as StaticHttp
import Renderer
import Url


manifest : Manifest.Config Pages.PathKey
manifest =
    { backgroundColor = Nothing
    , categories = [ Pages.Manifest.Category.education ]
    , displayMode = Manifest.Standalone
    , orientation = Manifest.Portrait
    , description = siteTagline
    , iarcRatingId = Nothing
    , name = siteName
    , themeColor = Nothing
    , startUrl = pages.index
    , shortName = Nothing
    , sourceIcon = images.favicon
    }


main : Pages.Platform.Program Model Msg Metadata Document
main =
    Pages.Platform.init
        { init = \_ -> init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , documents = [ Markup.document ]
        , manifest = manifest
        , canonicalSiteUrl = canonicalSiteUrl
        , onPageChange = Nothing
        , internals = Pages.internals
        }
        |> Pages.Platform.toProgram


type alias Model =
    {}


init : ( Model, Cmd Msg )
init =
    ( Model, Cmd.none )


type alias Msg =
    ()


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        () ->
            ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


view :
    List ( PagePath Pages.PathKey, Metadata )
    ->
        { path : PagePath Pages.PathKey
        , frontmatter : Metadata
        }
    ->
        StaticHttp.Request
            { view : Model -> Document -> { title : String, body : PlainHtml.Html Msg }
            , head : List (Head.Tag Pages.PathKey)
            }
view allPages meta =
    StaticHttp.succeed
        { view =
            \_ document ->
                let
                    { title, body } =
                        viewPage allPages meta document
                in
                { title = title
                , body =
                    Renderer.render
                        body
                }
        , head = head meta.frontmatter
        }


viewPage :
    List ( PagePath Pages.PathKey, Metadata )
    -> { path : PagePath Pages.PathKey, frontmatter : Metadata }
    -> Document
    -> { title : String, body : Renderer.Rendered Msg }
viewPage allPages page document =
    case page.frontmatter of
        Metadata.Index ->
            { title = siteName
            , body = viewIndex allPages
            }

        Metadata.Article metadata ->
            let
                title =
                    metadata.title ++ ", an unnecessarily bad design"
            in
            { title = title
            , body =
                let
                    navigation =
                        -- Do not display navigation on the index.
                        if pages.index == page.path then
                            []

                        else
                            [ Renderer.navigation pages.index ]

                    questionInline =
                        Document.plainText metadata.question
                            |> Document.TextInline
                            |> Document.FlatInline
                            |> List.singleton
                            |> Document.Paragraph

                    fullDocument =
                        Document.Title title :: questionInline :: document

                    rendered =
                        Renderer.renderDocument metadata fullDocument
                in
                Renderer.body
                    (navigation
                        ++ [ Renderer.mainContent
                                [ rendered ]
                           ]
                    )
            }


viewIndex : List ( PagePath Pages.PathKey, Metadata ) -> Html Msg
viewIndex allPages =
    let
        things =
            List.filterMap
                (\( path, meta ) ->
                    case meta of
                        Metadata.Article articleMeta ->
                            Just ( path, articleMeta )

                        _ ->
                            Nothing
                )
                allPages
    in
    Renderer.body
        [ Renderer.title siteName
        , Html.ul
            [ css
                [ Css.margin zero
                , Css.marginTop (rem 1)
                , Css.marginBottom (rem 3)
                , Css.padding zero
                , Css.listStyleType Css.none
                , Css.Global.children
                    [ Css.Global.typeSelector "li"
                        [ Css.Global.adjacentSiblings
                            [ Css.Global.typeSelector "li"
                                [ Css.marginTop (rem 0.5)
                                ]
                            ]
                        ]
                    ]
                ]
            ]
            (List.map
                (\( path, meta ) ->
                    let
                        title =
                            [ Document.ReferenceInline { text = [ Document.plainText meta.title ], path = path } ]
                                |> List.map Document.FlatInline

                        question =
                            [ Document.plainText meta.question ]
                                |> List.map Document.TextInline
                                |> List.map Document.FlatInline
                    in
                    Html.li []
                        [ Renderer.heading title
                        , Renderer.paragraph [] question
                        ]
                )
                things
            )
        , let
            repoUrl =
                { protocol = Url.Https
                , host = "github.com"
                , port_ = Nothing
                , path = "/y0hy0h/unnecessarily-bad-design"
                , query = Nothing
                , fragment = Nothing
                }

            contribute =
                [ Document.TextInline (Document.plainText "If you know more examples of unnecessarily bad design, contribute to the ")
                , Document.LinkInline { text = [ Document.plainText "GitHub repository" ], url = repoUrl }
                , Document.TextInline (Document.plainText ".")
                ]
                    |> List.map Document.FlatInline
          in
          Renderer.paragraph [ Renderer.backgroundTextStyle ] contribute
        ]


commonHeadTags : List (Head.Tag Pages.PathKey)
commonHeadTags =
    []


{-| <https://developer.twitter.com/en/docs/tweets/optimize-with-cards/overview/abouts-cards>
<https://htmlhead.dev>
<https://html.spec.whatwg.org/multipage/semantics.html#standard-metadata-names>
<https://ogp.me/>
-}
head : Metadata -> List (Head.Tag Pages.PathKey)
head metadata =
    commonHeadTags
        ++ (case metadata of
                Metadata.Index ->
                    Seo.summary
                        { canonicalUrlOverride = Nothing
                        , siteName = siteName
                        , image = favicon
                        , description = siteTagline
                        , title = siteName
                        , locale = Just "en"
                        }
                        |> Seo.website

                Metadata.Article meta ->
                    Seo.summaryLarge
                        { canonicalUrlOverride = Nothing
                        , siteName = siteName
                        , image = favicon
                        , description = siteTagline
                        , locale = Just "en"
                        , title = meta.title
                        }
                        |> Seo.website
           )


canonicalSiteUrl : String
canonicalSiteUrl =
    "https://y0hy0h.github.io/unnecessarily-bad-design/"


siteName : String
siteName =
    "Unnecessarily bad design"


siteTagline : String
siteTagline =
    "Things that hard to use for no damn reason."


favicon : Seo.Image PathKey
favicon =
    { url = images.favicon
    , alt = "A stove knob's label highlighting which heating plate it controls"
    , dimensions = Nothing
    , mimeType = Nothing
    }
