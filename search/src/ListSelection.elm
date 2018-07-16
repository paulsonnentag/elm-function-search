module ListSelection exposing (ListSelection, fromList, next, prev, getSelectedItem, getItems)

import Array exposing (Array)


type ListSelection a
    = ListSelection (ListSelectionData a)


type alias ListSelectionData a =
    { selectedItem : Int
    , items : Array a
    }


fromList : List a -> ListSelection a
fromList list =
    ListSelection
        { selectedItem = 0
        , items = Array.fromList list
        }


next : ListSelection a -> ListSelection a
next list =
    case list of
        ListSelection data ->
            ListSelection { data | selectedItem = (data.selectedItem + 1) % (Array.length data.items) }


prev : ListSelection a -> ListSelection a
prev list =
    case list of
        ListSelection data ->
            ListSelection { data | selectedItem = (data.selectedItem - 1) % (Array.length data.items) }


getSelectedItem : ListSelection a -> Maybe a
getSelectedItem list =
    case list of
        ListSelection { selectedItem, items } ->
            Array.get selectedItem items


getItems : ListSelection a -> List a
getItems list =
    case list of
        ListSelection { items } ->
            Array.toList items
