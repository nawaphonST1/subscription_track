import jenkins.model.*
import hudson.security.*

def instance = Jenkins.getInstance()
instance.setDisableRememberMe(true)
instance.setSecurityRealm(new HudsonPrivateSecurityRealm(false))
instance.setAuthorizationStrategy(new AuthorizationStrategy.Unsecured())
instance.save()
println("--> [SubTracker] Unsecured authorization strategy configured for fast local/VM testing.")
