module App.Model exposing (initialModel, AppModel)

import User.Model as User exposing (Model, initialUser)

-- MODEL

type alias AppModel =
    { userModel : User.Model
    }


initialModel : AppModel
initialModel =
    { userModel = User.initialUser
    }



