port module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html
import Facebook
import User exposing (..)
import Html.Events exposing (onClick)
import Json.Encode as Encode exposing (..)
import Json.Decode as Decode exposing (..)
-- import Debug exposing (log)



-- MAIN


main =
    Html.programWithFlags
        { init = init
        , view = view
        , update = updateWithStorage
        , subscriptions = subscriptions
        }



-- MODEL


type alias AppModel =
    { userModel : User.Model
    }



-- INIT
initialModel : AppModel
initialModel =
    { userModel = User.initialUser
    }



init : Maybe (Encode.Value) -> ( AppModel, Cmd Msg )
init savedModel =
    case savedModel of
        Just value  ->
            Maybe.withDefault initialModel (Decode.decodeValue modelDecoder value |> resultToMaybe ) ! []
        _ -> 
            initialModel ! [] 


{--
Decode model from localstorage
 --}
modelDecoder : Decode.Decoder AppModel
modelDecoder =
  Decode.map4 modelConstructor
    (field "name" Decode.string) 
    (field "url" Decode.string)
    (field "loginStatus" Decode.string |> andThen User.loginStatusDecoder )
    (field "userType" Decode.string |> andThen User.userTypeDecoder )


{--
helper to create the model from the decoder
 --}
modelConstructor : String -> String -> User.LoginStatus -> User.UserType -> AppModel
modelConstructor name picture status userType =
    AppModel { name = name
    , url = picture
    , loginStatus = status
    , userType = userType
    }



resultToMaybe : Result String AppModel -> Maybe AppModel
resultToMaybe result =
  case result of
    Result.Ok model -> Just model
    Result.Err error -> Debug.log error Nothing
    

-- MESSAGE


type Msg
    = NoOp
    | Login
    | Logout
    | LoggedIn String
    | LoggedOut String
    | UserMsg User.Msg



-- PORTS


port userLoggedIn : (String -> msg) -> Sub msg


port userLoggedOut : (String -> msg) -> Sub msg


port setStorage : Encode.Value -> Cmd msg



-- SUBSCRIPTIONS


subscriptions : AppModel -> Sub Msg
subscriptions model =
    Sub.batch
        [ userLoggedIn LoggedIn
        , userLoggedOut LoggedOut
        ]



-- UPDATE


updateWithStorage : Msg -> AppModel -> ( AppModel, Cmd Msg )
updateWithStorage msg model =
    let
        ( newModel, cmds ) =
            update msg model
    in
        ( newModel
        , Cmd.batch [ setStorage (User.modelToValue newModel.userModel), cmds ]
        )


update : Msg -> AppModel -> ( AppModel, Cmd Msg )
update msg model =
    case msg of
        LoggedIn json ->
            let
                ( updatedUserModel, userCmd ) =
                    User.update (User.UserLoggedIn json) model.userModel
            in
                ( { model | userModel = updatedUserModel }, Cmd.map UserMsg userCmd )

        LoggedOut loggedOutMsg ->
            let
                ( updatedUserModel, userCmd ) =
                    User.update (User.UserLoggedOut loggedOutMsg) model.userModel
            in
                ( { model | userModel = updatedUserModel }, Cmd.none )

        Login ->
            ( model, Facebook.login {} )

        Logout ->
            ( model, Facebook.logout {} )

        _ ->
            ( model, Cmd.none )



-- VIEW


view : AppModel -> Html Msg
view app =
    case app.userModel.loginStatus of
        User.Connected ->
            div []
                [ div [] [ text app.userModel.name ]
                , loggedInHtml app.userModel.url
                ]

        _ ->
            div []
                [ div [] [ text app.userModel.name ]
                , loggedOutHtml
                ]


loggedInHtml : String -> Html Msg
loggedInHtml pic =
    div []
        [ img [ src pic ] []
        , button [ onClick Logout ] [ text "Logout" ]
        ]


loggedOutHtml : Html Msg
loggedOutHtml =
    button [ onClick Login ] [ text "Login" ]