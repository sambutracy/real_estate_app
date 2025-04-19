import Text "mo:base/Text";
import Bool "mo:base/Bool";
import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Option "mo:base/Option";
import Nat "mo:base/Nat";
import Time "mo:base/Time";
import Nat32 "mo:base/Nat32";
import Char "mo:base/Char";
import Int "mo:base/Int";
import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Nat8 "mo:base/Nat8";
import Iter "mo:base/Iter";
import Result "mo:base/Result";

actor {  // Removed name "Auth" as it was unused
  // Type definitions
  public type Role = {
    #Admin;
    #User;
  };

  public type User = {
    email: Text;
    passwordHash: Text;
    principal: Principal;
    createdAt: Int;
    role: Role;
  };
  
  public type Session = {
    token: Text;
    userId: Text;
    expiration: Int;
  };
  
  // Stable storage
  private stable var usersEntries : [(Text, User)] = [];
  private stable var sessionsEntries : [(Text, Session)] = [];
  
  private var users = HashMap.HashMap<Text, User>(0, Text.equal, Text.hash);
  private var sessions = HashMap.HashMap<Text, Session>(0, Text.equal, Text.hash);
  
  // Helper functions
  private func hashPassword(password: Text): Text {
    var hash : Nat = 0;
    for (char in password.chars()) {
      let charCode = Nat32.toNat(Char.toNat32(char));
      hash := (hash + charCode) * 31;
    };
    return Nat.toText(hash);
  };

  // Safe version of generatePrincipalFromEmail
  private func generatePrincipalFromEmail(email: Text) : Principal {
    // Create a seed with the full email address to ensure uniqueness
    let seed = Text.encodeUtf8(email # "-real-estate-app-fixed");
    
    // Create full 29-byte array for principal
    let principalBytes = Array.tabulate<Nat8>(29, func(i : Nat) : Nat8 {
      if (i == 0) {
        return 1; // Type byte for self-authenticating identity
      } else if (i < seed.size() + 1 and i - 1 < seed.size()) {
        // Use the email bytes directly with proper bounds checking
        return Blob.toArray(seed)[i - 1];
      } else {
        // Fill remaining bytes with email hash to ensure uniqueness
        return Nat8.fromNat(Nat32.toNat(Text.hash(email) % 256));
      };
    });
    
    return Principal.fromBlob(Blob.fromArray(principalBytes));
  };

  private func generateToken(): Text {
    let now = Int.abs(Time.now());
    let random = Int.abs(Time.now()) + 123456789;
    return Nat.toText(now) # "-" # Nat.toText(random);
  };

  // Core authentication functions
  public shared(_msg) func register(email: Text, password: Text): async Bool {
    if (Option.isSome(users.get(email))) {
      return false;
    };
    
    let timestamp = Time.now();
    let passwordHash = hashPassword(password);
    let userPrincipal = generatePrincipalFromEmail(email);
    
    let newUser: User = {
      email = email;
      passwordHash = passwordHash;
      principal = userPrincipal;
      createdAt = timestamp;
      role = #User;
    };
    
    users.put(email, newUser);
    return true;
  };
  
  public shared(_msg) func login(email: Text, password: Text) : async Result.Result<User, Text> {
    switch (users.get(email)) {
      case (null) { return #err("Invalid email or password"); };
      case (?user) {
        if (user.passwordHash == hashPassword(password)) {
          let token = generateToken();
          let expiration = Time.now() + 7 * 24 * 60 * 60 * 1000_000_000;
          
          let session: Session = {
            token = token;
            userId = email;
            expiration = expiration;
          };
          
          sessions.put(token, session);
          
          return #ok(user);  // Return the original user with proper principal
        } else {
          return #err("Invalid email or password");
        };
      };
    };
  };
  
  public query func verifySession(token: Text): async Bool {
    switch (sessions.get(token)) {
      case (null) { return false; };
      case (?session) {
        if (session.expiration < Time.now()) {
          sessions.delete(token);
          return false;
        };
        return true;
      };
    };
  };
  
  public func logout(token: Text): async Bool {
    switch (sessions.get(token)) {
      case (null) { return false; };
      case (_) {
        sessions.delete(token);
        return true;
      };
    };
  };
  
  // Admin management functions
  private func isAdmin(principal: Principal): Bool {
    for ((_, user) in users.entries()) {
      if (Principal.equal(user.principal, principal) and isUserAdmin(user)) {
        return true;
      };
    };
    return false;
  };

  private func isUserAdmin(user: User): Bool {
    switch (user.role) {
      case (#Admin) { return true; };
      case (_) { return false; };
    };
  };

  // Simplified admin functions - consolidated multiple redundant functions
  public shared(_msg) func promoteToAdmin(email: Text) : async Bool {
    switch (users.get(email)) {
      case (null) { return false; };
      case (?user) {
        let updatedUser: User = {
          email = user.email;
          passwordHash = user.passwordHash;
          principal = user.principal;
          createdAt = user.createdAt;
          role = #Admin;
        };
        users.put(email, updatedUser);
        return true;
      };
    };
  };
  
  public query func isAdminByEmail(email: Text) : async Bool {
    switch (users.get(email)) {
      case (null) { return false; };
      case (?user) {
        return isUserAdmin(user);
      };
    };
  };

  // Create initial admin
  public shared(_msg) func createInitialAdmin(email: Text, password: Text): async Bool {
    // Only allow this if no other admins exist
    for ((_, user) in users.entries()) {
      if (isUserAdmin(user)) {
        return false;
      };
    };
    
    let timestamp = Time.now();
    let passwordHash = hashPassword(password);
    let userPrincipal = generatePrincipalFromEmail(email);
    
    let newUser: User = {
      email = email;
      passwordHash = passwordHash;
      principal = userPrincipal;
      createdAt = timestamp;
      role = #Admin;
    };
    
    users.put(email, newUser);
    return true;
  };

  // User role functions
  public shared(_msg) func getUserRole(): async Text {
    let callerPrincipal = _msg.caller;
    
    for ((_, user) in users.entries()) {
      if (Principal.equal(user.principal, callerPrincipal)) {
        switch (user.role) {
          case (#Admin) { return "admin"; };
          case (#User) { return "user"; };
        };
      };
    };
    
    return "anonymous";
  };

  public query func getUserRoleByPrincipal(userPrincipal: Principal) : async Text {
    for ((_, user) in users.entries()) {
      if (Principal.equal(user.principal, userPrincipal)) {
        switch (user.role) {
          case (#Admin) { return "admin"; };
          case (#User) { return "user"; };
        };
      };
    };
    
    return "anonymous";
  };

  // Principal management
  // Fixed version that keeps the original principal
  public shared(_msg) func updateUserPrincipal(email: Text): async Bool {
    // Don't update the principal at all - just return success
    switch (users.get(email)) {
      case (null) { return false; };
      case (?user) {
        // Don't modify the user object
        return true;
      };
    };
  };

  // Debug functions
  public query func debugPrincipals() : async Text {
    var result = "Current principals in system:\n";
    
    for ((email, user) in users.entries()) {
      result #= email # ": " # Principal.toText(user.principal) # " - Role: ";
      
      switch (user.role) {
        case (#Admin) { result #= "admin"; };
        case (#User) { result #= "user"; };
      };
      
      result #= "\n";
    };
    
    return result;
  };

  public query func checkUserExists(email: Text) : async Bool {
    return Option.isSome(users.get(email));
  };

  public query func debugLogin(email: Text, password: Text) : async Text {
    switch (users.get(email)) {
      case (null) { return "User not found"; };
      case (?user) {
        if (user.passwordHash == hashPassword(password)) {
          return "Login would succeed with principal: " # Principal.toText(user.principal);
        } else {
          return "Password incorrect";
        };
      };
    };
  };

  // Add a debugging function to auth.mo
  public query func lookupPrincipalInfo(principal: Principal) : async Text {
    var result = "Looking up principal: " # Principal.toText(principal) # "\n";
    
    for ((email, user) in users.entries()) {
      result #= "Comparing with user: " # email # 
               "\nStored principal: " # Principal.toText(user.principal) # 
               "\nEqual: " # Bool.toText(Principal.equal(principal, user.principal)) # "\n\n";
    };
    
    return result;
  };

  // Add a debugging function to directly check a principal against stored ones
  public query func debugCheckPrincipal(principalText: Text) : async Text {
    let principal = Principal.fromText(principalText);
    var result = "Checking principal: " # principalText # "\n";
    
    for ((email, user) in users.entries()) {
      let match = Principal.equal(principal, user.principal);
      result #= "Comparing with user: " # email # 
               "\nStored principal: " # Principal.toText(user.principal) # 
               "\nEqual: " # Bool.toText(match) # 
               "\nRole: " # (if (isUserAdmin(user)) "admin" else "user") # "\n\n";
    };
    
    return result;
  };

  // Add a function to delete a user (for admin cleanup)
  public shared(_msg) func deleteUser(email: Text) : async Bool {
    switch (users.get(email)) {
      case (null) { return false; };
      case (_) {
        users.delete(email);
        return true;
      };
    };
  };

  // Add a function to delete all users (for complete reset)
  public shared(_msg) func deleteAllUsers() : async Bool {
    // Empty the users map
    for ((email, _) in users.entries()) {
      users.delete(email);
    };
    return true;
  };

  // System upgrade hooks
  system func preupgrade() {
    usersEntries := Iter.toArray(users.entries());
    sessionsEntries := Iter.toArray(sessions.entries());
  };

  system func postupgrade() {
    users := HashMap.fromIter<Text, User>(
      Iter.fromArray(usersEntries), 
      usersEntries.size(), 
      Text.equal, 
      Text.hash
    );
    
    sessions := HashMap.fromIter<Text, Session>(
      Iter.fromArray(sessionsEntries), 
      sessionsEntries.size(), 
      Text.equal, 
      Text.hash
    );
    
    usersEntries := [];
    sessionsEntries := [];
  };
};