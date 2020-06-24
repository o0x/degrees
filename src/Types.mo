import Hash "mo:base/Hash";

module {
    public type Vertex = Principal;
    public type UserId = Principal;

    public type Profile = {
        id: Principal;
        firstName: Text;
        lastName: Text;
        title: Text;
        company: Text;
        experience: Text;
        education: Text;
        imgUrl: Text;
    };
};