#!/usr/bin/env escript

% HELLO MR GRADER!!!!!
% To run this file, use this command:
% chmod +x super_crawler.escript 
% ./super_crawler.escript

-define(ROOT, "https://www.thelatinlibrary.com/").
-define(INDEX_URLS, [
    "https://www.thelatinlibrary.com/indices.html",
    "https://www.thelatinlibrary.com/classics.html",
    "https://www.thelatinlibrary.com/medieval.html",
    "https://www.thelatinlibrary.com/christian.html"
]).

% Run ONE crawler per index URL
main(_Args) ->
    ok = start_runtime(),
    Parent = self(),
    [spawn_link(fun() -> Parent ! {authors, collect_from_index(U)} end) || U <- ?INDEX_URLS],
    Authors = gather(length(?INDEX_URLS), #{}),
    ok = write_results(Authors),
    io:format("It is done, my lord. With your leave, I wrote ~B authors to results.txt~n", [maps:size(Authors)]).

start_runtime() ->
    application:ensure_all_started(inets),
    application:ensure_all_started(ssl),
    ok.

gather(0, Acc) -> Acc;
gather(N, Acc) ->
    receive
        {authors, Map} -> gather(N - 1, maps:merge(Acc, Map))
    end.

% Fetch the HTML, parse links, normalize URLs, and then save which authors are likely.
collect_from_index(BaseUrl) ->
    case fetch(BaseUrl) of
        {ok, Html} ->
            lists:foldl(
                fun({Href, Text}, Acc) ->

                    case normalize(Href, BaseUrl) of
                        {ok, Url} ->

                            case looks_like_author(Url, Text) of
                                true -> Acc#{Url => clean(Text)};
                                false -> Acc
                            end;

                        _ -> Acc
                    end

                end, #{}, links_and_text(Html));

        _ -> #{}
    end.

% First download the page and return the HTML from the successful responses
%   i.e. By successful responses, I mean HTTP 200 stuff
fetch(Url) ->
    Req = {Url, [{"user-agent", "latin-author-crawler/1.0"}]},
    case httpc:request(get, Req, [{timeout, 10000}], [{body_format, binary}]) of
        {ok, {{_, 200, _}, _, Body}} -> {ok, binary_to_list(Body)};
        _ -> error
    end.

% Extract the href and usable text stuff from each of the anchor tags. This comes
% from the page HTML
links_and_text(Html) ->
    Pattern = "<a[^>]*href\\s*=\\s*(?:\"([^\"]+)\"|'([^']+)'|([^\\s>]+))[^>]*>(.*?)</a>",
    case re:run(Html, Pattern, [global, caseless, dotall, {capture, [1,2,3,4], list}]) of
        {match, Ms} ->
            [{pick_href(A, B, C), strip_tags(T)} || [A, B, C, T] <- Ms];
        _ -> []
    end.

pick_href(A, _, _) when A =/= [] -> A;
pick_href([], B, _) when B =/= [] -> B;
pick_href([], [], C) -> C.

strip_tags(Text) ->
    clean(re:replace(Text, "<[^>]+>", "", [global, {return, list}])).

% Take the relative links and ensure they are returned as usable URLs.
normalize(Href, BaseUrl) ->
    case uri_string:resolve(Href, BaseUrl) of
        {error, _, _} -> {error, bad_uri};
        Abs ->

            case uri_string:parse(Abs) of
                #{host := Host0} = P ->
                    Host = string:lowercase(Host0),

                    case Host of
                        "thelatinlibrary.com" -> {ok, "https://www.thelatinlibrary.com" ++ maps:get(path, P, "/")};
                        "www.thelatinlibrary.com" -> {ok, "https://www.thelatinlibrary.com" ++ maps:get(path, P, "/")};
                        _ -> {error, out_of_scope}
                    end;

                _ -> {error, bad_uri}
            end

    end.

% There was a lot of issues related to the differences between author and page link
% This function ensures non of the non-essential links are preserved.
looks_like_author(Url, Text0) ->
    Path = maps:get(path, uri_string:parse(Url), "/"),
    OneSegment = length([P || P <- string:tokens(Path, "/"), P =/= ""]) =:= 1,
    HtmlOrSlug = lists:suffix(".html", Path) orelse (OneSegment andalso string:find(Path, ".") =:= nomatch),
    Text = string:lowercase(clean(Text0)),
    NotNav = Text =/= "" andalso
        string:find(Text, "home") =:= nomatch andalso
        string:find(Text, "latin library") =:= nomatch andalso
        string:find(Text, "classics") =:= nomatch andalso
        string:find(Text, "medieval") =:= nomatch andalso
        string:find(Text, "christian latin") =:= nomatch andalso
        string:find(Text, "lingua latina") =:= nomatch andalso
        string:find(Text, "new testament") =:= nomatch andalso
        string:find(Text, "vulgate") =:= nomatch,
    HtmlOrSlug andalso NotNav.

% Take the authors which have been retrieved from the final step and write them to 
% the results file. Everything will be tab separated with the :format thing below.
write_results(AuthorsMap) ->
    Pairs = lists:sort([{Name, Url} || {Url, Name} <- maps:to_list(AuthorsMap)]),
    Header = "author\turl\n",
    Rows = [io_lib:format("~s\t~s~n", [Name, Url]) || {Name, Url} <- Pairs],
    file:write_file("results.txt", lists:flatten([Header | Rows])).

% Normalize the final whitespace stuff in the text fields which have just bbeen extracted.
clean(Text) ->
    lists:flatten(
        string:trim(
            lists:map(fun($\t) -> $\s; ($\n) -> $\s; (C) -> C end, Text)
        )
    ).
