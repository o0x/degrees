import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import List "mo:base/List";
import Nat "mo:base/Nat";
import Option "mo:base/Option";
import Text "mo:base/Hash";

import Bfs "./Bfs";
import Types "./Types";

/*
 Degrees of Separation
 -------------------
 Find a path between two Linkedup users and the degree of separation between them.

 Linkedup's Connectd canister uses a directed graph to store the connections, stored as an edge list
 and accessed as an adjacency list.
 Using a bi-directional breadth first search, find a path between two users and the degree 
 of separation between them.
 */

type Vertex = Types.Vertex;
type Profile = Types.Profile;
type UserId =  Types.UserId;
type CanisterId = Text;

actor Degrees {

 // private

    var connectdId: ?CanisterId = null;
    var linkedupId: ?CanisterId = null;

    func checkConnection( canisterId: CanisterId) : async Bool {
        let canister = actor (canisterId) : actor { healthcheck(): async Bool };
        let success = await canister.healthcheck();
        if(success) true
        else false
    };

    func prettyPrintPath(path: List.List<Vertex>, startProfile: Profile, endProfile: Profile) : async Text {
        // pretty print path for command line interface
        var message = "";
        
        if (Option.isSome(path) and Option.isSome(linkedupId)) {
            let linkedup = actor (Option.unwrap(linkedupId)) : actor { 
                get(userId: Vertex): async Profile;
            };
            
            var names = "";
            var edge = false;
            for (userId in Iter.fromList(path)) {
                if (edge == true) names #= " ----- "; edge := true;
                let profile = await linkedup.get(userId);
                names #= profile.firstName # " " # profile.lastName;
            };

            let dist = List.len<Vertex>(path) - 1;
            let n = Nat.toText( dist );
            var s = "s"; if (dist == 1) s := "";

            message := "                            Connected!                         \n" #
                        "                     " # n # " degree" # s #" of separation" #
                        "\n\n     " # names;
        } else {
            let name0 = startProfile.firstName # " " # startProfile.lastName;
            let name1 = endProfile.firstName # " " # endProfile.lastName;
            message := "        Not connected..." #
                        "\n\n         " # name0 # "          :(            " # name1 #
                        "\n\n                  ...you should introduce them!";
        };

        message := "\n\n     =======================================================\n\n" # message;
        message #= "\n\n     =======================================================\n\n";

        message
    };

    func searchLinkedup(term: Text) : async [Profile] {
        var p: [Profile] = [];
        if (Option.isSome(linkedupId)) {
            let linkedup = actor (Option.unwrap(linkedupId)) : actor { search(term: Text): async [Profile] };
            p := await linkedup.search(term);
        };
        p
    };

 // public

    // command line user interface

    public func run(startUser: Text, endUser: Text) : async Text {
        // just uses first matching user for each search term given
        await runIndexed(startUser, 0, endUser, 0)
    };

    public func findUser(term: Text) : async Text {
        let profiles: [Profile] = await searchLinkedup(term);
        var i = 0;
        var users = Array.foldl(
            func (t: Text, p: Profile) : Text {
                let out = t # Nat.toText(i) # ": " # p.firstName # " " # p.lastName # "\n";
                i += 1;
                out
            }, "", profiles
        );
        if (i == 0) return "\n - No matching users - \n"
        else        return "\nMatching users:\n" # users
    };

    public func runIndexed(startUser: Text, startIndex: Nat, endUser: Text, endIndex: Nat) : async Text {
        let s: [Profile] = await searchLinkedup(startUser);
        let e: [Profile] = await searchLinkedup(endUser);

        if (startIndex < s.len() and endIndex < e.len()) {
            let start = s[startIndex].id;
            let end = e[endIndex].id;
        
            let path = await getPath(start, end);
            return await prettyPrintPath(path, s[startIndex], e[endIndex]);
        };
        return "\n - No matching user(s) - \n"
    };

    // main service

    public func getPath(start: UserId, end: UserId) : async List.List<UserId> {
        // runs a search and returns the path found, if any

        if (Option.isSome(connectdId)) {
            let connectd = actor (Option.unwrap(connectdId)) : actor { getConnections(user: UserId): async [UserId] };

            let bfs = Bfs.Bfs(start, end, connectd.getConnections);
            await bfs.run();

            return bfs.getPath()
        };
        return null
    };

    // admin

    public func registerCanisters(connectdId_: CanisterId, linkedupId_: CanisterId) : async Text {
        //  example id: "ic:897BE41A286369174E"
        if ( (await checkConnection(connectdId_)) and (await checkConnection(linkedupId_)) ) {
            connectdId := ?connectdId_;
            linkedupId := ?linkedupId_;
            return "Canisters connected successfully."
        };
        "" /* traps and reports unreachable */
    };

};
