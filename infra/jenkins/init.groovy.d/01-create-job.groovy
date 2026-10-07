import jenkins.model.Jenkins
import org.jenkinsci.plugins.workflow.job.WorkflowJob
import org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition
import hudson.plugins.git.GitSCM
import hudson.plugins.git.BranchSpec
import hudson.plugins.git.UserRemoteConfig

def jenkins = Jenkins.getInstance()
def jobName = "subtracker-api"

if (jenkins.getItem(jobName) == null) {
    try {
        WorkflowJob job = jenkins.createProject(WorkflowJob.class, jobName)
        String repoUrl = "https://github.com/nawaphonST1/subscription_track.git"
        String branch = "*/feat/system-integration-test-and-fix"
        
        List<UserRemoteConfig> userRemoteConfigs = [new UserRemoteConfig(repoUrl, null, null, null)]
        List<BranchSpec> branches = [new BranchSpec(branch)]
        
        GitSCM scm = new GitSCM(userRemoteConfigs, branches, false, Collections.emptyList(), null, null, Collections.emptyList())
        CpsScmFlowDefinition flowDefinition = new CpsScmFlowDefinition(scm, "Jenkinsfile")
        flowDefinition.setLightweight(true)
        job.setDefinition(flowDefinition)
        job.save()
        println("--> [SubTracker] Pipeline job '${jobName}' created successfully pointing to branch '${branch}'!")
    } catch (Throwable t) {
        println("--> [SubTracker] Error auto-creating job: " + t.getMessage())
    }
}
