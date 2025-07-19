import Quickshell

import "scripts/fzf.js" as Fzf
import "scripts/fuzzysort.js" as Fuzzy
import QtQuick

Singleton {
    required property list<QtObject> list
    property string key: "name"
    property bool useFuzzy: false
    property var extraOpts: ({})

    readonly property var fzf: useFuzzy ? [] : new Fzf.Finder(list, Object.assign({
        selector: e => e[key]
    }, extraOpts))
    readonly property list<var> fuzzyPrepped: useFuzzy ? list.map(e => ({
                [key]: e[key],
                _item: e
            })) : []

    function transformSearch(search: string): string {
        return search;
    }

    function query(search: string): list<var> {
        search = transformSearch(search);
        if (!search)
            return [...list];

        if (useFuzzy)
            return Fuzzy.go(search, fuzzyPrepped, Object.assign({
                all: true,
                key
            }, extraOpts)).map(r => r.obj._item);

        return fzf.find(search).sort((a, b) => {
            if (a.score === b.score)
                return a.item[key].trim().length - b.item[key].trim().length;
            return b.score - a.score;
        }).map(r => r.item);
    }
}
