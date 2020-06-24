import Debug "mo:base/Debug";
import Principal "mo:base/Principal";
import Iter "mo:base/Iter";
import Option "mo:base/Option";
import Queue "./Queue";
import List "mo:base/List";
import Hash "mo:base/Hash";

import Types "./Types";
import Store "./Store";

module {

type Vertex = Types.Vertex;
type Queue<T> = Queue.Queue<T>;
type Store<K,V> = Store.Store<K,V>;
type Entry = { parent: ?Vertex; level: Nat };

public class Bfs (startVertex: Vertex, 
                  endVertex: Vertex,
                  getAdjacent: shared (Vertex) -> async [Vertex] ) {

    // Bi-directional breadth first search on a directed graph.
    // Returns first of the shortest paths found, there may be others with the same distance.

    let PROGRESS = true;       // toggles a progress indicator in console output

 // private

    let eq:      (Vertex,Vertex)->Bool = func(x,y) { x==y };
    let keyHash: (Vertex)->Hash.Hash   = func(v)   { Principal.hash(v) };

    // members -------

    var commonVertex: ?Vertex = null;
    var shortestDistance: ?Nat = null;
    
    let s0 = { var table = Store.Store<Vertex,Entry>(eq, keyHash);
               var queue = Queue.nil<Vertex>(); };

    let s1 = { var table = Store.Store<Vertex,Entry>(eq, keyHash);
               var queue = Queue.nil<Vertex>(); };
    
    // ----------------

    func exists(v: Vertex, s: Store<Vertex,Entry>) : Bool {
        switch (s.get(v)) {
            case null { false };
            case (?_) { true };
        };
    };

    func shortestDistanceExceeded(level: Nat) : Bool {
        if ( Option.isSome(shortestDistance) and level >= Option.unwrap(shortestDistance) ) {
            return true
        };
        return false
    };

    func traverse(from: Vertex, to: Vertex, table: Store<Vertex,Entry>) : List.List<Vertex> {
        // starting with the to vertex, traverse the parent table back up.

        var path = List.nil<Vertex>();
        
        var current = to;
        path := List.push(current, path);
        
        label w
        while (current != from) {
            switch (table.get(current)) {
                case null { break w };
                case (?entry) {
                    switch (entry.parent) {
                        case null { break w };
                        case (?p) { current := p };
                    };
                };
            };
            path := List.push(current, path);
        };

        return path
    };

    func searchNext(s: { var table: Store<Vertex,Entry>;
                         var queue: Queue<Vertex>; },
                    oppositeTable: Store<Vertex,Entry>) : async () {

        let (v, q) = Queue.dequeue(s.queue);
        s.queue := q;

        let fromVertex = Option.unwrap(v);
        let currentLevel = Option.unwrap(s.table.get(fromVertex)).level;
        
        if (shortestDistanceExceeded(currentLevel)) {
            s.queue := Queue.nil<Vertex>();
            return
        };

        await searchAdjacent(fromVertex, currentLevel, s, oppositeTable);
    };

    func searchAdjacent(fromVertex: Vertex,
                        currentLevel: Nat,
                        s: { var table: Store<Vertex,Entry>;
                             var queue: Queue<Vertex>; },
                        oppositeTable: Store<Vertex,Entry>) : async () {

        // get adjacent vertices from the external graph, enqueue unvisited, 
        // if a common vertex with a shorter distance is found store it and 
        // update the shortest distance.
    
        let adjVs = await getAdjacent(fromVertex);      // external call

        for (toVertex in Iter.fromArray(adjVs)) {
            if (not exists(toVertex, s.table)) {        // unvisited (this side)
                let entry = {parent = ?fromVertex; level = currentLevel + 1};
                s.table.set(toVertex, entry);
                s.queue := Queue.enqueue(toVertex, s.queue);

                if (exists(toVertex, oppositeTable)) {  // common vertex
                    let distance = currentLevel + 1 + Option.unwrap(oppositeTable.get(toVertex)).level;
                    if (Option.isNull(shortestDistance) or distance < Option.unwrap(shortestDistance)) {
                        shortestDistance := ?distance;
                        commonVertex := ?toVertex;
                    };
                };
            };
        };
    };

 // public

    public func run() : async () {
        s0.table.set(startVertex, {parent = null; level = 0});

        if (startVertex == endVertex) {
            commonVertex := ?startVertex;
            return
        };

        s1.table.set(endVertex, {parent = null; level = 0});
        s0.queue  := Queue.enqueue(startVertex, s0.queue);        
        s1.queue  := Queue.enqueue(endVertex,   s1.queue);
        
        if PROGRESS Debug.print("Searching the graph...");

        // search adjacent vertices until the shortest path is found

        while (not Queue.isEmpty(s0.queue) or not Queue.isEmpty(s1.queue)) {
            if PROGRESS Debug.print("...");
            if (not Queue.isEmpty(s0.queue)) await searchNext(s0, s1.table);
            if (not Queue.isEmpty(s1.queue)) await searchNext(s1, s0.table);
        };

        if PROGRESS Debug.print(". . . done!");
    };

    public func getPath() : List.List<Vertex> {
        // returns a list of all vertices visited from the start vertex to the end vertex inclusive, 
        // via the common vertex, or null if no path was found.
        // TODO: include directions ??

        switch (commonVertex) {
            case (null) null;
            case (?c) {
                let path0 = traverse(startVertex, c, s0.table);
                var path1 = traverse(endVertex, c, s1.table);
                path1 := Option.unwrap(List.rev(path1)).1;
                
                return List.append(path0, path1);
            };
        };
    };

};

};