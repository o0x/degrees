## Linkedup - Degrees of Separation

Find a path between two Linkedup users and the degree of separation between them.

Command line user interface and service, for the Internet Computer.

Notes:
Current SDK limitations prevent query calls between canisters, so timeouts can occur on larger graphs.
There will be some graphs for which you cannot resolve paths (eg if a user in the middle connects outwards with no reciprocation).

### Install

In a local Internet Computer development environment (see https://sdk.dfinity.org)...

-----

Build and install the Linkedup application, found here: https://github.com/dfinity-lab/linkedup. Take note of the canister ids, for example:

```
    Installing code for canister connectd, with canister_id ic:D467B38589AF2A1D40
    Installing code for canister linkedup, with canister_id ic:9597FCEA454531CEB4
```

Leave 'dfx start' running in the Linkedup terminal, you'll install Degrees on the same local replica.

-----

Build and install Degrees of Separation, in a new terminal:

```
    cd path/to/degrees
    dfx build && dfx canister install degrees
```

Register the Linkedup canisters, passing the ids above in this order: **connectd**, **linkedup**, eg:
```
    dfx canister call degrees registerCanisters '("ic:D467B38589AF2A1D40", "ic:9597FCEA454531CEB4")'
```

-----


### Example usage

Open the Linkedup canister frontend in a web browser, create some profiles and connect them to each other (you'll need multiple sandboxed browser instances to do this, either use features like privacy mode or a plugin like Firefox's [Containers](https://addons.mozilla.org/en-GB/firefox/addon/multi-account-containers/)), then...

In the terminal, search for a path between any two users, for example:

```
    dfx canister call degrees run '("Frodo", "Sam")'
```

And await a result (the terminal running dfx start will show progress), eg:

```
     =======================================================

                            Connected!
                     2 degrees of separation

     Frodo Baggins ----- Peregrin Took ----- Samwise Gamgee

     =======================================================

```

If multiple Linkedup profiles share the same search term, the above will use the first matched user. Instead, you can try a search term first:

```
    dfx canister call degrees findUser '("S")'

    >
    Matching users:
    0: Samwise Gamgee
    1: Smeagol
```

You can then use the indexes provided to select users, eg:

```
    dfx canister call degrees runIndexed '("Frodo", 0, "S", 1)'
```

Try changing the user details on Linkedup, making some new connections, and running Degrees again. It will always use the latest data from the Linkedup application.

-----


### Further usage

The base Degrees service is the public method getPath:

```
    "getPath": (UserId, UserId) -> (List);

where
    type UserId = principal;
    type List = 
     opt record {
       UserId;
       List;
     };
```

Any canister can call into Degrees getPath with valid principals as user ids. The list returned is a linked list of principals. The degree of separation is the length of the list minus one.
