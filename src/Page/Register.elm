module Page.Register exposing (Model, Msg(..), init, update, view)

import Data.Kinto
import Data.Session exposing (Session)
import Html as H
import Html.Attributes as HA
import Html.Events as HE
import Http
import Kinto
import Page.Common.Components
import Page.Common.Notifications as Notifications
import Request.KintoAccount
import Route


type alias Model =
    { title : String
    , registerForm : RegisterForm
    , notifications : Notifications.Model
    , userInfoData : Data.Kinto.KintoData Request.KintoAccount.UserInfo
    , approved : Bool
    }


type alias RegisterForm =
    { email : String
    , password : String
    , password2 : String
    }


emptyRegisterForm : RegisterForm
emptyRegisterForm =
    { email = "", password = "", password2 = "" }


type Msg
    = UpdateRegisterForm RegisterForm
    | Register
    | NotificationMsg Notifications.Msg
    | UserInfoReceived (Result Http.Error Request.KintoAccount.UserInfo)
    | OnApproved Bool


init : Session -> ( Model, Cmd Msg )
init session =
    ( { title = "Inscription"
      , registerForm = emptyRegisterForm
      , notifications = Notifications.init
      , userInfoData = Data.Kinto.NotRequested
      , approved = False
      }
    , Cmd.none
    )


update : Session -> Msg -> Model -> ( Model, Cmd Msg )
update session msg model =
    case msg of
        UpdateRegisterForm registerForm ->
            ( { model | registerForm = registerForm }, Cmd.none )

        Register ->
            registerAccount session.kintoURL model

        UserInfoReceived (Ok userInfo) ->
            ( { model | userInfoData = Data.Kinto.Received userInfo }
            , Cmd.none
            )

        UserInfoReceived (Err error) ->
            let
                kintoError =
                    Kinto.extractError error
            in
            ( { model
                | notifications =
                    "Inscription échouée : "
                        ++ Kinto.errorToString kintoError
                        |> Notifications.addError model.notifications
                , userInfoData = Data.Kinto.NotRequested
              }
            , Cmd.none
            )

        NotificationMsg notificationMsg ->
            ( { model | notifications = Notifications.update notificationMsg model.notifications }, Cmd.none )

        OnApproved approved ->
            ( { model | approved = approved }, Cmd.none )


isRegisterFormComplete : RegisterForm -> Bool -> Bool
isRegisterFormComplete registerForm approved =
    approved && registerForm.email /= "" && registerForm.password /= "" && registerForm.password == registerForm.password2


registerAccount : String -> Model -> ( Model, Cmd Msg )
registerAccount kintoURL model =
    if isRegisterFormComplete model.registerForm model.approved then
        ( { model | userInfoData = Data.Kinto.Requested }
        , Request.KintoAccount.register kintoURL model.registerForm.email model.registerForm.password UserInfoReceived
        )

    else
        ( model, Cmd.none )


view : Session -> Model -> ( String, List (H.Html Msg) )
view session { title, notifications, registerForm, userInfoData, approved } =
    ( title
    , [ H.div [ HA.class "hero" ]
            [ H.div [ HA.class "hero__container" ]
                [ H.img [ HA.src session.staticFiles.logo_ca12, HA.class "hero__logo" ] []
                , H.h1 [] [ H.text "Inscription" ]
                ]
            ]
      , H.div [ HA.class "main" ]
            [ H.map NotificationMsg (Notifications.view notifications)
            , H.div [ HA.class "section section-white" ]
                [ H.div [ HA.class "container" ]
                    [ case userInfoData of
                        Data.Kinto.Received userInfo ->
                            H.div []
                                [ H.text "Votre compte a été créé ! Il vous reste à l'activer : un mail vient de vous être envoyé avec un code d'activation. "
                                ]

                        _ ->
                            viewRegisterForm registerForm userInfoData approved
                    ]
                ]
            ]
      ]
    )


viewRegisterForm : RegisterForm -> Request.KintoAccount.UserInfoData -> Bool -> H.Html Msg
viewRegisterForm registerForm userInfoData approved =
    let
        formComplete =
            isRegisterFormComplete registerForm approved

        buttonState =
            if formComplete then
                case userInfoData of
                    Data.Kinto.Requested ->
                        Page.Common.Components.Loading

                    _ ->
                        Page.Common.Components.NotLoading

            else
                Page.Common.Components.Disabled

        submitButton =
            Page.Common.Components.submitButton "Créer ce compte" buttonState

        passwordsDontMatch =
            registerForm.password2 /= "" && registerForm.password /= registerForm.password2
    in
    H.form
        [ HE.onSubmit Register ]
        [ H.h1 [] [ H.text "Formulaire de création de compte" ]
        , H.p []
            [ H.text "L'utilisation de ce service est régi par une "
            , H.a
                [ Route.href Route.Convention ]
                [ H.text "charte de bonne conduite" ]
            , H.text " et des "
            , H.a
                [ Route.href Route.CGU ]
                [ H.text "conditions générales d'utilisation" ]
            , H.text "."
            ]
        , H.div [ HA.class "form__group" ]
            [ H.label [ HA.for "email" ] [ H.text "Email (adresse académique uniquement)" ]
            , H.input
                [ HA.type_ "email"
                , HA.id "email"
                , HA.value registerForm.email
                , HE.onInput <| \email -> UpdateRegisterForm { registerForm | email = email }
                ]
                []
            ]
        , H.div [ HA.class "form__group" ]
            [ H.label [ HA.for "password" ] [ H.text "Mot de passe" ]
            , H.input
                [ HA.type_ "password"
                , HA.value registerForm.password
                , HE.onInput <| \password -> UpdateRegisterForm { registerForm | password = password }
                ]
                []
            ]
        , H.div [ HA.class "form__group" ]
            [ H.label [ HA.for "password2" ] [ H.text "Confirmer le mot de passe" ]
            , H.input
                [ HA.type_ "password"
                , HA.value registerForm.password2
                , HA.class <|
                    if passwordsDontMatch then
                        "invalid"

                    else
                        ""
                , HE.onInput <| \password2 -> UpdateRegisterForm { registerForm | password2 = password2 }
                ]
                []
            ]
        , H.div
            [ HA.class "form__group" ]
            [ H.input
                [ HA.id "approve_CGU"
                , HA.type_ "checkbox"
                , HA.checked approved
                , HE.onCheck OnApproved
                ]
                []
            , H.label [ HA.for "approveCGU", HA.class "label-inline" ]
                [ H.text "J'ai lu et j'accepte d'adhérer à la charte de bonne conduite" ]
            ]
        , submitButton
        ]
