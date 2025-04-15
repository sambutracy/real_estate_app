import Text "mo:base/Text";
import Bool "mo:base/Bool";
import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Option "mo:base/Option";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Time "mo:base/Time";
import Nat32 "mo:base/Nat32";
import Char "mo:base/Char";
import Int "mo:base/Int";
import Blob "mo:base/Blob";
import Array "mo:base/Array";

// Remove these two imports that require the "ic" package
// import Delegation "mo:ic/Delegation";
// import Crypto "mo:ic/Crypto";

actor Auth {
  // User type
  public type User = {
    email: Text;
    passwordHash: Text;
    principal: Principal;
    createdAt: Int;
  };
  
  // Session type
  public type Session = {
    token: Text;
    userId: Text;
    expiration: Int;
  };
  
  // Store users by email
  private var users = HashMap.HashMap<Text, User>(0, Text.equal, Text.hash);
  
  // Store sessions
  private var sessions = HashMap.HashMap<Text, Session>(0, Text.equal, Text.hash);
  
  // Simple hash function - not cryptographically secure but works for demo
  private func hashPassword(password: Text): Text {
    var hash : Nat = 0;
    for (char in password.chars()) {
      let charCode = Char.toNat32(char);
      hash := (hash + Nat32.toNat(charCode)) * 31;
    };
    return Nat.toText(hash);
  };
  
  private func generatePrincipal(email: Text, timestamp: Int) : Principal {
    // Create a shorter seed using just a hash of the email + timestamp
    let seed = Text.concat(email, Int.toText(timestamp));
    
    // Create a shorter, fixed-length array (29 bytes max for principals)
    var bytes = Array.init<Nat8>(29, 0);
    
    // Simple hash function to distribute values
    var hashValue : Nat32 = 0;
    for (char in seed.chars()) {
      let charCode = Char.toNat32(char);
      hashValue := (hashValue +% charCode) *% 31;
      
      // Distribute the hash across the byte array
      let pos = Nat32.toNat(hashValue % 29);
      bytes[pos] := Nat8.fromNat(Nat32.toNat(hashValue % 256));
    };
    
    // Add some randomness based on timestamp
    let timeValue = Int.abs(timestamp) % 256;
    let timeByte = Nat8.fromNat(Int.abs(timeValue)); // Int.abs already returns a Nat
    bytes[0] := timeByte;
    
    // Create a blob from the bytes
    let blob = Blob.fromArray(Array.freeze(bytes));
    
    return Principal.fromBlob(blob);
  };
  
  // Register a new user
  public shared(_msg) func register(email: Text, password: Text): async Bool {
    if (Option.isSome(users.get(email))) {
      return false; // User already exists
    };
    
    let passwordHash = hashPassword(password);
    let timestamp = Time.now();
    
    // Generate a unique principal 
    let userPrincipal = generatePrincipal(email, timestamp);
    
    let newUser: User = {
      email = email;
      passwordHash = passwordHash;
      principal = userPrincipal;
      createdAt = timestamp;
    };
    
    users.put(email, newUser);
    return true;
  };
  
  // Login returning both token and principal text
  public func login(email: Text, password: Text): async ?(Text, Text) {
    switch (users.get(email)) {
      case (null) { 
        return null; // User not found
      };
      case (?user) {
        let passwordHash = hashPassword(password);
        if (passwordHash == user.passwordHash) {
          // Create token
          let currentTime = Time.now();
          let timeText = Int.toText(currentTime);
          let token = Text.concat(email, timeText);
          
          // Create session
          let session: Session = {
            token = token;
            userId = email;
            expiration = currentTime + (7 * 24 * 60 * 60 * 1_000_000_000); // 7 days in nanoseconds
          };
          
          sessions.put(token, session);
          
          // Return both token and principal
          return ?(token, Principal.toText(user.principal));
        } else {
          return null; // Incorrect password
        };
      };
    };
  };
  
  // REMOVE the loginWithDelegation function for now
  
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
  public query func getPrincipalFromToken(token: Text): async Text {
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
}