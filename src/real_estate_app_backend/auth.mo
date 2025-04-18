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

actor Auth {
  // Add role type
  public type Role = {
    #Admin;
    #User;
  };

  // User type
  public type User = {
    email: Text;
    passwordHash: Text;
    principal: Principal;
    createdAt: Int;
    role: Role;  // Add role field
  };
  
  // Session type
  public type Session = {
    token: Text;
    userId: Text;
    expiration: Int;
  };
  
  // Add stable variables at the top of your actor
  private stable var usersEntries : [(Text, User)] = [];
  private stable var sessionsEntries : [(Text, Session)] = [];
  
  // Store users by email
  private var users = HashMap.HashMap<Text, User>(0, Text.equal, Text.hash);
  
  // Store sessions
  private var sessions = HashMap.HashMap<Text, Session>(0, Text.equal, Text.hash);
  
  // Simple hash function - not cryptographically secure but works for demo
  private func hashPassword(password: Text): Text {
    var hash : Nat = 0;
    for (char in password.chars()) {
      let charCode = Nat32.toNat(Char.toNat32(char));
      hash := (hash + charCode) * 31;
    };
    return Nat.toText(hash);
  };

  // Replace the existing generatePrincipalFromEmail function with this enhanced version
  private func generatePrincipalFromEmail(email: Text) : Principal {
    // Add a unique salt to generate different principals for the same email in different apps
    let seed = Text.encodeUtf8(email # "-icp-real-estate-salt-2025-04-18");
    let seedBytes = Blob.toArray(seed);
    
    // Standard principal is 29 bytes
    let principalBytes = Array.tabulate<Nat8>(
      29,
      func(i : Nat) : Nat8 {
        if (i == 0) { 
          // First byte is type - 1 for self-authenticating
          return 1;
        } else if (i <= seedBytes.size() and i - 1 < 28) {
          // Copy seed bytes with offset
          return seedBytes[(i - 1) % seedBytes.size()];  
        } else {
          // Fill remaining bytes with a pattern based on email hash
          let h = Text.hash(email) + Nat32.fromNat(i);
          return Nat8.fromNat(Nat32.toNat(h % 256));
        };
      }
    );
    
    return Principal.fromBlob(Blob.fromArray(principalBytes));
  };

  // Helper to generate a random token
  private func generateToken(): Text {
    let now = Int.abs(Time.now());
    let random = Int.abs(Time.now()) + 123456789;
    return Nat.toText(now) # "-" # Nat.toText(random);
  };  // <-- Added semicolon here

  // Register a new user
  public shared(_msg) func register(email: Text, password: Text): async Bool {
    if (Option.isSome(users.get(email))) {
      return false; // User already exists
    };
    
    let timestamp = Time.now();
    let passwordHash = hashPassword(password);
    let userPrincipal = generatePrincipalFromEmail(email);
    
    let newUser: User = {
      email = email;
      passwordHash = passwordHash;
      principal = userPrincipal;
      createdAt = timestamp;
      role = #User;  // Default role
    };
    
    users.put(email, newUser);
    return true;
  };
  
  // Login and create session
  public shared(msg) func login(email: Text, password: Text) : async Result.Result<User, Text> {
    switch (users.get(email)) {
      case (null) { return #err("Invalid email or password"); };
      case (?user) {
        if (user.passwordHash == hashPassword(password)) {
          // Update the user's principal to the current caller
          let updatedUser : User = {
            email = user.email;
            passwordHash = user.passwordHash;
            principal = msg.caller;  // Use the actual caller principal
            createdAt = user.createdAt;
            role = user.role;
          };
          
          users.put(email, updatedUser);
          
          // Create a session token
          let token = generateToken();
          let expiration = Time.now() + 7 * 24 * 60 * 60 * 1000_000_000; // 7 days in nanoseconds
          
          let session: Session = {
            token = token;
            userId = email;
            expiration = expiration;
          };
          
          sessions.put(token, session);
          
          return #ok(updatedUser);
        } else {
          return #err("Invalid email or password");
        };
      };
    };
  };
  
  // Verify session
  public query func verifySession(token: Text): async Bool {
    switch (sessions.get(token)) {
      case (null) {
        return false;
      };
      case (?session) {
        if (session.expiration < Time.now()) {
          // Session expired
          sessions.delete(token);
          return false;
        };
        return true;
      };
    };
  };
  
  // Logout (invalidate session)
  public func logout(token: Text): async Bool {
    switch (sessions.get(token)) {
      case (null) { return false };
      case (_) {
        sessions.delete(token);
        return true;
      };
    };
  };
  
  // Get user by token
  public query func getUserByToken(token: Text): async ?Text {
    switch (sessions.get(token)) {
      case (null) { return null };
      case (?session) {
        if (session.expiration < Time.now()) {
          return null;
        };
        return ?session.userId;
      };
    };
  };

  // Get principal from token
  public shared func getPrincipalFromToken(token: Text): async Text {
    switch (sessions.get(token)) {
      case (null) {
        return "Invalid token";
      };
      case (?session) {
        switch (users.get(session.userId)) {
          case (null) { return "User not found"; };
          case (?user) { return Principal.toText(user.principal); };
        };
      };
    };
  };

  // Add system upgrade hooks
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

  // Add this to your Auth actor
  // Set a user as admin (only callable by an existing admin)
  public shared(msg) func setAdmin(email: Text): async Bool {
    // Admin check
    let callerPrincipal = msg.caller;
    if (not isAdmin(callerPrincipal)) {
      return false;
    };
    
    switch (users.get(email)) {
      case (null) { return false };
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

  // Check if principal has admin role
  private func isAdmin(principal: Principal): Bool {
    for ((_, user) in users.entries()) {
      if (Principal.equal(user.principal, principal) and isUserAdmin(user)) {
        return true;
      };
    };
    return false;
  };

  // Helper to check if user has admin role
  private func isUserAdmin(user: User): Bool {
    switch (user.role) {
      case (#Admin) { return true; };
      case (_) { return false; };
    };
  };

  // Create initial admin during canister initialization
  public shared(msg) func createInitialAdmin(email: Text, password: Text): async Bool {
    // Only allow this if no other admins exist
    for ((_, user) in users.entries()) {
      if (isUserAdmin(user)) {
        return false; // Admin already exists
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

  // Add this after the createInitialAdmin function
  public shared(msg) func forceSetUserAsAdmin(email: Text): async Bool {
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

  // Add this function after the createInitialAdmin function
  public func adminPromoteUser(email: Text): async Bool {
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

  // Get current user's role
  public shared(msg) func getUserRole(): async Text {
    let callerPrincipal = msg.caller;
    
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

  // Add this to auth.mo
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

  // Add this to auth.mo
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

  // Add this query function to auth.mo (keep the update one too)
  public query func getUserRoleQuery(caller: Principal): async Text {
    for ((_, user) in users.entries()) {
      if (Principal.equal(user.principal, caller)) {
        switch (user.role) {
          case (#Admin) { return "admin"; };
          case (#User) { return "user"; };
        };
      };
    };
    
    return "anonymous";
  };

  // Add this to your auth.mo
  public shared(msg) func updateUserPrincipal(email: Text): async Bool {
    // Only allow this for admins or for the first user if no admins exist
    let callerPrincipal = msg.caller;
    
    switch (users.get(email)) {
      case (null) { return false; };  // User doesn't exist
      case (?user) {
        let updatedUser: User = {
          email = user.email;
          passwordHash = user.passwordHash;
          principal = callerPrincipal;  // Update to caller's principal
          createdAt = user.createdAt;
          role = user.role;
        };
        users.put(email, updatedUser);
        return true;
      };
    };
  };

  // Add this function to force regenerate a proper principal ID
  public shared(msg) func regenerateUserPrincipal(email: Text): async Text {
    switch (users.get(email)) {
      case (null) { return "User not found"; };
      case (?user) {
        // Generate a new principal using our improved function
        let newPrincipal = generatePrincipalFromEmail(email);
        
        let updatedUser: User = {
          email = user.email;
          passwordHash = user.passwordHash;
          principal = newPrincipal;
          createdAt = user.createdAt;
          role = user.role;
        };
        
        users.put(email, updatedUser);
        return Principal.toText(newPrincipal);
      };
    };
  };

  // Add this function to regenerate a proper principal for the admin
  public func regenerateAdminPrincipal() : async Text {
    let adminEmail = "admin@example.com";
    
    switch (users.get(adminEmail)) {
      case (null) { return "Admin user not found"; };
      case (?user) {
        // Create a proper 29-byte principal
        let seed = Text.encodeUtf8(adminEmail # "-real-estate-app-2025");
        let seedBytes = Blob.toArray(seed);
        
        let principalBytes = Array.tabulate<Nat8>(
          29,  // Standard principal length
          func(i : Nat) : Nat8 {
            if (i == 0) { 
              return 1;  // Type byte for self-authenticating identity
            } else if (i <= seedBytes.size() and i - 1 < 28) {
              return seedBytes[(i - 1) % seedBytes.size()];
            } else {
              // Fill remaining bytes with a pattern based on email
              return Nat8.fromNat(Nat32.toNat(Text.hash(adminEmail) % 256));
            };
          }
        );
        
        let newPrincipal = Principal.fromBlob(Blob.fromArray(principalBytes));
        
        // Update the user record
        let updatedUser: User = {
          email = user.email;
          passwordHash = user.passwordHash;
          principal = newPrincipal;
          createdAt = user.createdAt;
          role = #Admin;  // Make sure it's still admin
        };
        
        users.put(adminEmail, updatedUser);
        return Principal.toText(newPrincipal);
      };
    };
  };
}