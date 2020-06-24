import HashMap "mo:base/HashMap";
import Hash "mo:base/Hash";
import Iter "mo:base/Iter";

module {
    public class Store<K,V>( isEq:(K, K) -> Bool,
                             keyHash: K -> Hash.Hash) {

        let store = HashMap.HashMap<K,V>(20, isEq, keyHash);

        public func get(k:K) : ?V {
            store.get(k:K);
        };

        public func set(k:K, v:V) {
            ignore store.set(k:K, v:V);
        };

        public func iter() : Iter.Iter<(K,V)> {
            store.iter()
        };
    };
};