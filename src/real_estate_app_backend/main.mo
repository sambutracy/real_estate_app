import Array "mo:base/Array";
import Hash "mo:base/Hash";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Text "mo:base/Text";

actor RealEstate {
    // Property type
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
        forRent: Bool;
    };

    // Store properties in a HashMap
    private stable var nextId : Nat = 0;
    private var properties = HashMap.HashMap<Nat, Property>(0, Nat.equal, Hash.hash);

    // Create a new property listing
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
        let owner = msg.caller;
        let property : Property = {
            id = nextId;
            owner = owner;
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

        properties.put(nextId, property);
        nextId += 1;
        return nextId - 1;
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
                    return Text.contains(Text.toLower(p.location), #text Text.toLower(searchTerm));
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
}