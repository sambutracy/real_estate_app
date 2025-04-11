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
import Random "mo:base/Random";
import Blob "mo:base/Blob";
import Nat8 "mo:base/Nat8";

actor Auth {
  // User type
  public type User = {
    email: Text;
    passwordHash: Text;
    principal: Principal;
    createdAt: Int;
    resetToken: ?Text;
    resetTokenExpiry: ?Int;
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
      resetToken = null;
      resetTokenExpiry = null;
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

  // Add this function to your auth canister
  public func getPrincipalFromToken(token : Text) : async Text {
    switch (sessions.get(token)) {
      case (null) {
        return "Invalid token";
      };
      case (?session) {
        // Get the user by email (userId) from the session
        switch (users.get(session.userId)) {
          case (null) {
            return "User not found";
          };
          case (?user) {
            // Return the principal as text
            return Principal.toText(user.principal);
          };
        };
      };
    };
  };

  // Request password reset
  public func requestPasswordReset(email: Text) : async Bool {
    switch (users.get(email)) {
      case (null) {
        return false; // User not found
      };
      case (?user) {
        // Generate a random token using proper Random API
        let chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
        var token = "";
        
        // Get random bytes
        let randomBlob = await Random.blob();
        let randomBytes = Blob.toArray(randomBlob);
        var i = 0;
        
        // Use the random bytes to select characters
        while (i < 10 and i < randomBytes.size()) {
          let randomByte = Nat8.toNat(randomBytes[i]);
          let index = randomByte % chars.size();
          
          // Extract character at the random index
          var j = 0;
          label charLoop for (c in chars.chars()) {
            if (j == index) {
              token := token # Char.toText(c);
              break charLoop;
            };
            j += 1;
          };
          
          i += 1;
        };
        
        // Set token expiry (24 hours from now)
        let currentTime = Time.now();
        let expiryTime = currentTime + (24 * 60 * 60 * 1000000000); // 24 hours in nanoseconds
        
        // Update user with reset token
        let updatedUser = {
          email = user.email;
          passwordHash = user.passwordHash;
          principal = user.principal;
          createdAt = user.createdAt;
          resetToken = ?token;
          resetTokenExpiry = ?expiryTime;
        };
        
        users.put(email, updatedUser);
        return true;
      };
    };
  };

  // Reset password using token
  public func resetPassword(email: Text, token: Text, newPassword: Text) : async Bool {
    switch (users.get(email)) {
      case (null) {
        return false; // User not found
      };
      case (?user) {
        switch (user.resetToken, user.resetTokenExpiry) {
          case (?storedToken, ?expiry) {
            // Check if token matches and hasn't expired
            let currentTime = Time.now();
            if (storedToken == token and currentTime < expiry) {
              // Hash the new password
              let newPasswordHash = hashPassword(newPassword);
              
              // Update user with new password and clear reset token
              let updatedUser = {
                email = user.email;
                passwordHash = newPasswordHash;
                principal = user.principal;
                createdAt = user.createdAt;
                resetToken = null;
                resetTokenExpiry = null;
              };
              
              users.put(email, updatedUser);
              return true;
            } else {
              return false; // Invalid token or expired
            };
          };
          case _ {
            return false; // No reset token was issued
          };
        };
      };
    };
  };
}