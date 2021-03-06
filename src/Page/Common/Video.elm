module Page.Common.Video exposing (details, keywords, player)

import Data.Kinto
import Html as H
import Html.Attributes as HA
import Html.Events as HE
import Json.Decode as Decode
import Markdown
import Page.Common.Dates
import Route
import Time


player : msg -> Data.Kinto.Attachment -> H.Html msg
player canplayMessage attachment =
    H.video
        [ HA.src <| attachment.location

        -- For some reason, using HA.type_ doesn't properly add the mimetype
        , HA.attribute "type" attachment.mimetype
        , HA.controls True
        , HA.preload "metadata"
        , HE.on "canplay" (Decode.succeed canplayMessage)
        ]
        [ H.text "Désolé, votre navigateur ne supporte pas le format de cette video" ]


details : Time.Zone -> Data.Kinto.Video -> Data.Kinto.ProfileData -> H.Html msg
details timezone video profileData =
    let
        authorName =
            case profileData of
                Data.Kinto.Received profile ->
                    profile.name

                _ ->
                    video.profile
    in
    H.div
        [ HA.class "video-details" ]
        [ H.h3 [] [ H.text video.title ]
        , H.div []
            [ H.time [] [ H.text <| Page.Common.Dates.posixToDate timezone video.creation_date ]
            , H.text " "
            , H.a [ Route.href <| Route.Profile (Just video.profile) ] [ H.text authorName ]
            ]
        , Markdown.toHtml [] video.description
        ]


keywords : Data.Kinto.Video -> H.Html msg
keywords video =
    if video.keywords /= [] then
        video.keywords
            |> List.map
                (\keyword ->
                    H.div [ HA.class "label" ]
                        [ H.text keyword ]
                )
            |> H.div [ HA.class "video-keywords" ]

    else
        H.text ""
