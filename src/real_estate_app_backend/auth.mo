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
      let charCode = Nat32.toNat(Char.toNat32(char));
      hash := (hash + charCode) * 31;
    };
    return Nat.toText(hash);
  };
  
  // Register a new user
  public shared(msg) func register(email: Text, password: Text): async Bool {
    if (Option.isSome(users.get(email))) {
      return false; // User already exists
    };
    
    let passwordHash = hashPassword(password);
    let newUser: User = {
      email = email;
      passwordHash = passwordHash;
      principal = msg.caller;
      createdAt = Time.now();
    };
    
    users.put(email, newUser);
    return true;
  };
  
  // Login and create session
  public func login(email: Text, password: Text): async ?Text {
    switch (users.get(email)) {
      case (null) { 
        return null; // User not found
      };
      case (?user) {
        let passwordHash = hashPassword(password);
        if (passwordHash == user.passwordHash) {
          // Convert Time.now() to Nat when needed for text concatenation
          let currentTime = Time.now();
          let timeText = Int.toText(currentTime);
          
          // Create a token using email and timestamp
          let token = Text.concat(email, timeText);
          
          // Create session
          let session: Session = {
            token = token;
            userId = email;
            expiration = currentTime + (7 * 24 * 60 * 60 * 1_000_000_000); // 7 days in nanoseconds
          };
          
          sessions.put(token, session);
          return ?token;
        } else {
          return null; // Incorrect password
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
}