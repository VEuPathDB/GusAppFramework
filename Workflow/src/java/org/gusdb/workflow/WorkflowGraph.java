package org.gusdb.workflow;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class WorkflowGraph {
    private List<String> params = new ArrayList<String>();
    private List<WorkflowStep> steps = new ArrayList<WorkflowStep>();
    private Map<String, WorkflowStep> stepsByName = new HashMap<String, WorkflowStep>();
    private Map<String,String> constants = new HashMap<String,String>();

    public WorkflowGraph() {}

    public void addConstant(NamedValue constant) {
	constants.put(constant.getName(),constant.getValue());
    }
    
    public void addParam(String paramName) {
	params.add(paramName);
    }
    
    public void addStep(WorkflowStep step) {
        step.setWorkflowGraph(this);
        String stepName = step.getName();
        if (stepsByName.containsKey(stepName))
            Utilities.error("non-unique step name: '" + stepName + "'");
        stepsByName.put(stepName, step);
        steps.add(step);
        step.substituteConstantValues(constants);
    }

    String getHomeDir() {
        return homeDir;
    }
    
    private void makeParentChildLinks() {
	// make the parent/child links from the remembered dependencies
	for (WorkflowStep step : steps) {
            for (Name dependName : step.getDependsNames()) {
                String stepName = step.getName();
                WorkflowStep parent = stepsByName.get(dependName.getName());
                if (parent == null) 
                    Utilities.error("step '" + stepName + "' depends on '"
                          + dependName + "' which is not found");
                step.addParent(parent);
            }
        }
    }
    
    public String toString() {
        return "Constants" + nl + constants.toString() + nl + nl
        + "Steps" + nl + steps.toString();
    }

}
