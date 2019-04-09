module Route exposing (Route(..), fromUrl, href, pushUrl, toString)

import Browser exposing (Document)
import Browser.Navigation as Nav
import Html exposing (Attribute)
import Html.Attributes as Attr
import String.Normalize
import Url exposing (Url)
import Url.Parser as Parser exposing ((</>), (<?>), Parser)
import Url.Parser.Query as Query


type Route
    = Home
    | Search (Maybe String)
    | PeerTubeAccount String
    | About
    | Participate
    | Newsletter
    | CGU
    | Convention
    | PrivacyPolicy
    | Admin
    | Video String String
    | Login
    | Register
    | ResetPassword
    | SetNewPassword String String
    | Activate String String
    | Profile String
    | Comments


parser : Parser (Route -> a) a
parser =
    Parser.oneOf
        [ Parser.map Home Parser.top
        , Parser.map Search (Parser.s "videos" <?> Query.string "categorie")
        , Parser.map PeerTubeAccount (Parser.s "peertube" </> Parser.s "profil" </> Parser.string)
        , Parser.map About (Parser.s "apropos")
        , Parser.map Participate (Parser.s "participer")
        , Parser.map Newsletter (Parser.s "infolettre")
        , Parser.map CGU (Parser.s "CGU")
        , Parser.map Convention (Parser.s "Charte")
        , Parser.map PrivacyPolicy (Parser.s "PolitiqueConfidentialite")
        , Parser.map Admin (Parser.s "admin")
        , Parser.map Video (Parser.s "video" </> Parser.string </> Parser.string)
        , Parser.map Login (Parser.s "connexion")
        , Parser.map Register (Parser.s "inscription")
        , Parser.map ResetPassword (Parser.s "oubli-mot-de-passe")
        , Parser.map SetNewPassword (Parser.s "nouveau-mot-de-passe" </> Parser.string </> Parser.string)
        , Parser.map Activate (Parser.s "activation" </> Parser.string </> Parser.string)
        , Parser.map Profile (Parser.s "profil" </> Parser.string)
        , Parser.map Comments (Parser.s "commentaires")
        ]


fromUrl : Url -> Maybe Route
fromUrl url =
    Parser.parse parser url


href : Route -> Attribute msg
href route =
    Attr.href (toString route)


pushUrl : Nav.Key -> Route -> Cmd msg
pushUrl key route =
    Nav.pushUrl key (toString route)


toString : Route -> String
toString route =
    let
        pieces =
            case route of
                Home ->
                    []

                Search search ->
                    search
                        |> Maybe.map
                            (\justSearch ->
                                [ "videos?categorie=" ++ justSearch ]
                            )
                        |> Maybe.withDefault [ "videos" ]

                PeerTubeAccount accountName ->
                    [ "peertube", "profil", accountName ]

                About ->
                    [ "apropos" ]

                Participate ->
                    [ "participer" ]

                Newsletter ->
                    [ "infolettre" ]

                CGU ->
                    [ "CGU" ]

                Convention ->
                    [ "Charte" ]

                PrivacyPolicy ->
                    [ "PolitiqueConfidentialite" ]

                Admin ->
                    [ "admin" ]

                Video videoID title ->
                    [ "video"
                    , videoID
                    , title
                        |> String.Normalize.slug
                    ]

                Login ->
                    [ "connexion" ]

                Register ->
                    [ "inscription" ]

                ResetPassword ->
                    [ "oubli-mot-de-passe" ]

                SetNewPassword username temporaryPassword ->
                    [ "nouveau-mot-de-passe"
                    , username
                    , temporaryPassword
                    ]

                Activate username activationKey ->
                    [ "activation"
                    , username
                    , activationKey
                    ]

                Profile profile ->
                    [ "profil"
                    , profile
                    ]

                Comments ->
                    [ "commentaires" ]
    in
    "/" ++ String.join "/" pieces
