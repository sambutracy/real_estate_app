import HashMap "mo:base/HashMap";
import Hash "mo:base/Hash";
import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Auth "canister:auth";

actor RealEstate {
    // Define stable variables INSIDE the actor
    private stable var nextPropertyIdStable: Nat = 1;
    private stable var propertiesEntries: [(Nat, Property)] = [];

    // Property type definition
    public type Property = {
        id: Nat;
        owner: Principal;
        title: Text;
        description: Text;
        price: Nat;
        imageUrl: Text;
        location: Text;
        bedrooms: Nat;
        bathrooms: Nat;
        squareFootage: Nat;
        forSale: Bool;
        forRent: Bool
    };

    // Use this in place of a regular variable for nextPropertyId
    private var nextPropertyId: Nat = nextPropertyIdStable;

    // Custom hash function for Nat that handles large values better
    private func natHash(n: Nat) : Hash.Hash {
        // This hash function uses bit operations to ensure all bits are considered
        let hash = Nat32.fromNat(n);
        let rotated = (hash << 5) | (hash >> 27);  // 5-bit left rotation
        return (hash ^ rotated) & 0x3fffffff;  // XOR and mask to 30 bits
    };

    // Initialize the properties HashMap
    private let properties = HashMap.fromIter<Nat, Property>(
        Iter.fromArray(propertiesEntries), 
        10, 
        Nat.equal, 
        Hash.hash
    );

    // Add system upgrade hooks INSIDE the actor
    system func preupgrade() {
        // Save properties data
        propertiesEntries := Iter.toArray(properties.entries());
        nextPropertyIdStable := nextPropertyId;
    };

    system func postupgrade() {
        // Restore from stable variables after upgrade
        propertiesEntries := [];
    };

    // Get user role - forward call to Auth canister
    public shared(msg) func getUserRole() : async Text {
        // Get the current caller principal
        let caller = msg.caller;
        
        // Check if the caller is anonymous
        if (Principal.isAnonymous(caller)) {
            return "anonymous";
        };
        
        // Call the Auth canister
        return await Auth.getUserRoleByPrincipal(caller);
    };

    // Create a new property listing (admin only)
    public shared(msg) func createProperty(
        title: Text, 
        description: Text, 
        price: Nat, 
        imageUrl: Text, 
        location: Text,
        bedrooms: Nat,
        bathrooms: Nat,
        squareFootage: Nat,
        forSale: Bool,
        forRent: Bool
    ) : async Nat {
        // Get caller's principal
        let caller = msg.caller;
        
        // Check if caller is admin
        let role = await Auth.getUserRoleByPrincipal(caller);
        if (role != "admin") {
            return 0; // Not authorized
        };
        
        // Add property logic
        let id = nextPropertyId;
        nextPropertyId += 1;
        
        let newProperty: Property = {
            id = id;
            owner = caller;
            title = title;
            description = description;
            price = price;
            imageUrl = imageUrl;
            location = location;
            bedrooms = bedrooms;
            bathrooms = bathrooms;
            squareFootage = squareFootage;
            forSale = forSale;
            forRent = forRent;
        };
        
        properties.put(id, newProperty);
        return id;
    };

    // Get all properties
    public query func getAllProperties() : async [Property] {
        return Iter.toArray(properties.vals());
    };

    // Get a specific property by ID
    public query func getProperty(id: Nat) : async ?Property {
        return properties.get(id);
    };

    // Update a property (only by the owner)
    public shared(msg) func updateProperty(
        id: Nat,
        title: Text,
        description: Text,
        price: Nat,
        imageUrl: Text,
        location: Text,
        bedrooms: Nat,
        bathrooms: Nat,
        squareFootage: Nat,
        forSale: Bool,
        forRent: Bool
    ) : async Bool {
        let caller = msg.caller;
        
        switch (properties.get(id)) {
            case (null) {
                return false;
            };
            case (?existingProperty) {
                if (existingProperty.owner != caller) {
                    return false;
                };
                
                let updatedProperty : Property = {
                    id = id;
                    owner = caller;
                    title = title;
                    description = description;
                    price = price;
                    imageUrl = imageUrl;
                    location = location;
                    bedrooms = bedrooms;
                    bathrooms = bathrooms;
                    squareFootage = squareFootage;
                    forSale = forSale;
                    forRent = forRent;
                };
                
                properties.put(id, updatedProperty);
                return true;
            };
        };
    };

    // Delete a property (only by the owner)
    public shared(msg) func deleteProperty(id: Nat) : async Bool {
        let caller = msg.caller;
        
        switch (properties.get(id)) {
            case (null) {
                return false;
            };
            case (?existingProperty) {
                if (existingProperty.owner != caller) {
                    return false;
                };
                
                properties.delete(id);
                return true;
            };
        };
    };

    // Search properties by location
    public query func searchByLocation(searchTerm: Text) : async [Property] {
        let searchResults = Iter.toArray(
            Iter.filter(
                properties.vals(), 
                func (p: Property) : Bool {
                    return Text.contains(Text.toLowercase(p.location), #text(Text.toLowercase(searchTerm)));
                }
            )
        );
        return searchResults;
    };

    // Filter properties by criteria
    public query func filterProperties(
        minBedrooms: ?Nat, 
        maxPrice: ?Nat, 
        forSale: ?Bool,
        forRent: ?Bool
    ) : async [Property] {
        let allProperties = Iter.toArray(properties.vals());
        
        return Array.filter(allProperties, func (p: Property) : Bool {
            let bedroomsMatch = switch(minBedrooms) {
                case (null) true;
                case (?min) p.bedrooms >= min;
            };
            
            let priceMatch = switch(maxPrice) {
                case (null) true;
                case (?max) p.price <= max;
            };
            
            let saleMatch = switch(forSale) {
                case (null) true;
                case (?sale) p.forSale == sale;
            };
            
            let rentMatch = switch(forRent) {
                case (null) true;
                case (?rent) p.forRent == rent;
            };
            
            return bedroomsMatch and priceMatch and saleMatch and rentMatch;
        });
    };

    // Add a function to check if a user is authenticated
    public query func whoami(caller : Principal) : async Text {
        return "Your identity: " # Principal.toText(caller);
    };

    // Add a special admin check that recognizes short principals
    public func isAdminByPrincipalText(principalText: Text): async Bool {
        // Check if this is our admin with short principal
        if (Text.equal(principalText, "2vxsx-fae")) {
            return true;
        };
        
        // Call the Auth canister
        let role = await Auth.getUserRoleByPrincipal(Principal.fromText(principalText));
        return Text.equal(role, "admin");
    }
}