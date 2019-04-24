module Helpers exposing
    ( app
    , areStatements
    , areStatementsSansMeta
    , binOp
    , case_
    , fails
    , fakeMeta
    , integer
    , isApplicationSansMeta
    , isExpression
    , isExpressionSansMeta
    , isStatement
    , isStatementSansMeta
    , list
    , record
    , recordUpdate
    , tuple
    , var
    )

import Ast exposing (parse, parseExpression, parseStatement)
import Ast.BinOp exposing (operators)
import Ast.Expression exposing (Expression(..), ExpressionSansMeta(..), MExp, dropExpressionMeta, dropMExpMeta)
import Ast.Helpers exposing (WithMeta)
import Ast.Statement exposing (ExportSet(..), Statement(..), Type(..), dropStatementMeta)
import Expect exposing (..)



-- Structures

app : MExp -> MExp -> MExp
app left right =
    fakeMeta (Application left right)


record =
    fakeMeta << Record


recordUpdate : String -> List ( WithMeta String, MExp ) -> MExp
recordUpdate name =
    fakeMeta << RecordUpdate (fakeMeta name)


var : String -> MExp
var name =
    mvar 0 0 name


integer =
    fakeMeta << Integer


binOp name l r =
    fakeMeta <| BinOp name l r


tuple =
    fakeMeta << Tuple


case_ mexp cases =
    fakeMeta <| Case mexp cases


list =
    fakeMeta << List


mvar : Int -> Int -> String -> MExp
mvar line column name =
    { meta = { line = line, column = column }, e = Variable [ name ] }



-- Helpers


fails : String -> Expectation
fails s =
    case parseExpression operators s of
        Err _ ->
            Expect.pass

        _ ->
            Expect.fail (s ++ " expected to fail")


isExpression : MExp -> String -> Expectation
isExpression e i =
    case parseExpression operators (String.trim i) of
        Ok ( _, _, r ) ->
            Expect.equal e.e r.e

        Err ( _, { position }, es ) ->
            Expect.fail ("failed to parse: " ++ i ++ " at position " ++ toString position ++ " with errors: " ++ toString es)


isExpressionSansMeta : MExp -> String -> Expectation
isExpressionSansMeta e i =
    case parseExpression operators (String.trim i) of
        Ok ( _, _, r ) ->
            Expect.equal (dropMExpMeta e) (dropMExpMeta r)

        Err ( _, a, es ) ->
            Expect.fail ("failed to parse: " ++ i ++ " at position " ++ toString a.position ++ " rest: |" ++ a.input ++ "| with errors: " ++ toString es)


isApplicationSansMeta : MExp -> List MExp -> String -> Expectation
isApplicationSansMeta fn args i =
    case parseExpression operators (String.trim i) of
        Ok ( _, _, app ) ->
            let
                l =
                    List.foldl (flip ApplicationSM)
                        (dropMExpMeta fn)
                        (List.map dropMExpMeta args)

                r =
                    dropMExpMeta app
            in
            Expect.equal l r

        Err ( _, { position }, es ) ->
            Expect.fail ("failed to parse: " ++ i ++ " at position " ++ toString position ++ " with errors: " ++ toString es)


isStatement : Statement -> String -> Expectation
isStatement s i =
    case parseStatement operators i of
        Ok ( _, _, r ) ->
            Expect.equal r s

        Err ( _, { position }, es ) ->
            Expect.fail ("failed to parse: " ++ i ++ " at position " ++ toString position ++ " with errors: " ++ toString es)


isStatementSansMeta : Statement -> String -> Expectation
isStatementSansMeta s i =
    case parseStatement operators i of
        Ok ( _, _, r ) ->
            Expect.equal (dropStatementMeta r) (dropStatementMeta s)

        Err ( _, { position }, es ) ->
            Expect.fail ("failed to parse: " ++ i ++ " at position " ++ toString position ++ " with errors: " ++ toString es)


areStatements : List Statement -> String -> Expectation
areStatements s i =
    case parse i of
        Ok ( _, _, r ) ->
            Expect.equal r s

        Err ( _, { position }, es ) ->
            Expect.fail ("failed to parse: " ++ i ++ " at position " ++ toString position ++ " with errors: " ++ toString es)


areStatementsSansMeta : List Statement -> String -> Expectation
areStatementsSansMeta s i =
    case parse i of
        Ok ( _, _, r ) ->
            Expect.equal (List.map dropStatementMeta r) (List.map dropStatementMeta s)

        Err ( _, { position }, es ) ->
            Expect.fail ("failed to parse: " ++ i ++ " at position " ++ toString position ++ " with errors: " ++ toString es)


fakeMeta : a -> WithMeta a
fakeMeta e =
    { meta = { line = 1, column = 1 }, e = e }
