package org.gusdb.workflow;

import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.security.NoSuchAlgorithmException;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Enumeration;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.HashSet;
import java.util.Properties;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

import org.xml.sax.SAXException;

/*
 * Overall subgraph strategy
 *  (1) parse a graph (starting w/ root graph)
       - read xml, and digest it
 *     - set parent child links
       - insert sugraph return nodes
 *  
 *  (2) expand subgraphs
 *     - starting with root graph, bottom up recursion through graph/subgraph
 *       hierarchy.  
 *     - for each graph
           - parse as in (1)
           - expand its subgraphs
             - replace each calling step with a pair of steps: caller and return
             - move caller's children to return; make return be caller's only child
           - insert it into parent graph
              - attach its root steps to parent caller
              - attach its leaf steps to parent return
 *   
 *  (3) in a final pass, set the path of each of the steps (top down recursion)
 * 
 * 
 */

public class WorkflowGraph<T extends WorkflowStep> {
    private List<String> paramDeclarations = new ArrayList<String>();
    private Map<String,String> constants = new LinkedHashMap<String,String>();
    private Map<String,String> globalConstants;
    private Map<String, T> globalStepsByName;
    private Workflow<T> workflow;
    private String xmlFileName;
    private String name;
    private boolean isGlobal = false;
    
    private List<T> subgraphCallerSteps = new ArrayList<T>(); 
    private List<T> rootSteps = new ArrayList<T>();
    
    // following state must be updated after expansion
    private Map<String, T> stepsByName = new HashMap<String, T>();
    private List<T> leafSteps = new ArrayList<T>();    
    private List<T> sortedSteps; 
    
    final static String nl = System.getProperty("line.separator");

    public WorkflowGraph() {}

    public void addConstant(NamedValue constant) {
	constants.put(constant.getName(),constant.getValue());
    }
    
    public void addGlobalConstant(NamedValue constant) {
        if (!isGlobal) 
                Utilities.error("In graph " + name + " a <globalConstant> is declared, but this graph is not global");
        globalConstants.put(constant.getName(),constant.getValue());
    }
    
    public void addParamDeclaration(Name paramName) {
	paramDeclarations.add(paramName.getName());
    }
    
    public void setName(String name) {
	this.name = name;
    }
    
    public boolean getIsGlobal() {
        return isGlobal;
    }

    void setIsGlobal(boolean isGlobal) {
	System.err.println("workflowgraph.setIsGlobal(" + isGlobal + ")");
	this.isGlobal = isGlobal;
    }

    public void addStep(T step) throws FileNotFoundException, IOException {
        step.setWorkflowGraph(this);
        String stepName = step.getBaseName();
        if (stepsByName.containsKey(stepName))
            Utilities.error("In graph " + name + ", non-unique step name: '" + stepName + "'");
        stepsByName.put(stepName, step);
        
        // if this graph is global, all its steps are global steps
        if (isGlobal) {
	    if (globalStepsByName.containsKey(stepName))
		Utilities.error("In graph " + name + ", non-unique global step name: '" + stepName + "'");
	    globalStepsByName.put(stepName, step);
	    System.err.println("workflowgraph.addstep:  adding step to global graph: " + stepName);
	}
    }
    
    void setWorkflow(Workflow<T> workflow) {
        this.workflow = workflow;
    }

    // a step that is a call to a globalSubgraph
    public void addGlobalStep(T step) throws FileNotFoundException, IOException {
	step.setIsGlobal(true);
	addStep(step);
    }
    
    Workflow<T> getWorkflow() {
        return workflow;
    }

    void setXmlFileName(String xmlFileName) {
     this.xmlFileName = xmlFileName;
    }
    
    void setGlobalConstants(Map<String,String> globalConstants) {
        this.globalConstants = globalConstants;
    }
    
    void setGlobalSteps(Map<String, T> globalSteps) {
        this.globalStepsByName = globalSteps;
    }
    
    // recurse through steps starting at roots.
    @SuppressWarnings("unchecked")
    List<T> getSortedSteps() {
        if (sortedSteps == null) {
	    int depthFirstOrder = 0;
            sortedSteps = new ArrayList<T>();
            for (T rootStep : rootSteps) {
                rootStep.addToList((List<WorkflowStep>)sortedSteps);
            }
	    // second pass to give everybody their order number;
	    for (T step : sortedSteps) step.setDepthFirstOrder(depthFirstOrder++); 
        }
        return sortedSteps;
    }
    
    Map<String, T> getStepsByName() {
        return stepsByName;
    }
    
    Collection<T> getSteps() {
        return stepsByName.values();
    }

    String getStepsAsString() {
    	StringBuffer buf = new StringBuffer();
	for (T step : getSteps()) {
	    buf.append(step.getFullName() + nl);
	}
	return buf.toString();
    }
    
    // clean up after building from xml
    void postprocessSteps() throws FileNotFoundException, IOException {
        
        for (T step : getSteps()) {

	    // make the parent/child links from the remembered dependencies
            makeParentChildLinks(step.getDependsNames(), step, "");

            // make the parent/child links from the remembered global dependencies
            makeParentChildLinks(step.getDependsGlobalNames(), step, "global");
                        
            // remember steps that call a subgraph
            if (step.getSubgraphXmlFileName() != null) {
                subgraphCallerSteps.add(step);
            }

	    // validate loadType
	    step.checkLoadTypes();
        }
        
    }
    
    void makeParentChildLinks(List<Name> dependsNames, T step, String globalStr) {
        for (Name dependName : dependsNames) {
	    String dName = dependName.getName();
            T parent = stepsByName.get(dName);
            if (parent == null) {      
                Utilities.error("In file " + xmlFileName + ", step '"
                                + step.getBaseName() + "' " + globalStr
				+ " depends on step '"
				+ dName + "' which is not found");
            }
	    if (parent.getIsGlobal()) 
		Utilities.error("Step " + step.getFullName() +
				" depends=" + dName + 
				" is not allowed because " + dName +
				" is a global subgraph");
            step.addParent(parent);
            parent.addChild(step);
        }
        
    }

    // delete steps with includeIf = false
    private void deleteExcludedSteps() throws java.io.IOException {
	
	Map<String, T> stepsTmp = new HashMap<String, T>(stepsByName);
        for (T step : stepsTmp.values()) {
            if (step.getExcludeFromGraph()) {
		for (WorkflowStep parent : step.getParents()) {
		    parent.removeChild(step);
		}
            
		for (WorkflowStep child : step.getChildren()) {
		    child.removeParent(step);
		    for (WorkflowStep parent : step.getParents()) {
			parent.addChild(child);
			child.addParent(parent);
		    }                
		}
		stepsByName.remove(step.getFullName());
	    }
	}
    }

    // for each step that calls a subgraph, add a fake step after it
    // called a "subgraph return child."  move all children dependencies to
    // the src.  this makes it easy to inject the subgraph between the step
    // and its src.
    @SuppressWarnings("unchecked")
    void insertSubgraphReturnChildren() {
	Map<String, T> currentStepsByName = new HashMap<String, T>(stepsByName);
        for (T step : currentStepsByName.values()) {
	    T returnStep = step;
            if (step.getIsSubgraphCall()) {
                returnStep = (T)step.insertSubgraphReturnChild();
                stepsByName.put(returnStep.getBaseName(), returnStep);
            }   
        }
        
    }
            
    void setRootsAndLeafs() {
	rootSteps = new ArrayList<T>();
	leafSteps = new ArrayList<T>();
        for (T step : getSteps()) {
            if (step.getParents().size() == 0) rootSteps.add(step);
            if (step.getChildren().size() == 0) leafSteps.add(step);
        }    
	sortedSteps = null;
    }
    
    public String toString() {
        return "Constants" + nl + constants.toString() + nl + nl
        + "Steps" + nl + getSortedSteps().toString();
    }
    

    @SuppressWarnings("unchecked")
    private void instantiateValues(String stepBaseName, String xmlFileName,
            Map<String, String> globalConstants, Map<String,String> paramValues,
            Map<String,Map<String,List<String>>> paramErrorsMap) {

	// confirm that caller has values for each of this graph's declared
	// parameters.  gather all such errors into fileErrorsMap for reporting
	// in total later
	for (String decl : paramDeclarations) {
	    if (!paramValues.containsKey(decl)) {
	        if (!paramErrorsMap.containsKey(xmlFileName))
	            paramErrorsMap.put(xmlFileName, new HashMap<String,List<String>>());
	        Map<String,List<String>> fileErrorsMap = paramErrorsMap.get(xmlFileName);
	        if (!fileErrorsMap.containsKey(stepBaseName)) 
	            fileErrorsMap.put(stepBaseName, new ArrayList<String>());
	        if (!fileErrorsMap.get(stepBaseName).contains(decl))
		    fileErrorsMap.get(stepBaseName).add(decl);
	    }
	}

	// substitute param values into constants
        for (String constantName : constants.keySet()) {
            String constantValue = constants.get(constantName);
	    String newConstantValue = 
		Utilities.substituteVariablesIntoString(constantValue, paramValues);
	    constants.put(constantName, newConstantValue);    
        }

	// substitute constants into constants
	Map fullyResolvedConstants = new HashMap<String,String>();
        for (String constantName : constants.keySet()) {
            String constantValue = constants.get(constantName);
	    String newConstantValue = 
		Utilities.substituteVariablesIntoString(constantValue,
							fullyResolvedConstants);
	    constants.put(constantName, newConstantValue);    
	    fullyResolvedConstants.put(constantName, newConstantValue);    
        }

	// substitute both into step params, includeIf and excludeIf
        for (T step : getSteps()) {
            step.substituteValues(globalConstants, false);
            step.substituteValues(constants, false);
            step.substituteValues(paramValues, true);
        }

	
    }
    /////////////////////////////////////////////////////////////////////////
    //   subgraph expansion
    /////////////////////////////////////////////////////////////////////////
    private void expandSubgraphs(String path, List<String> xmlFileNamesStack,
            Class<T> stepClass, Map<String, Map<String,List<String>>> paramErrorsMap,
            Map<String, T> globalSteps, Map<String,String> globalConstants) throws SAXException, Exception {

        // iterate through all subgraph callers
        for (T subgraphCallerStep : subgraphCallerSteps) {
        
            // get the xml file of a graph to insert, and check for circularity
            String subgraphXmlFileName = subgraphCallerStep.getSubgraphXmlFileName();
	    if (xmlFileNamesStack.contains(subgraphXmlFileName)) {
		throw new Exception("Circular reference to graphXmlFile '"
				    + subgraphXmlFileName + "'"
				    + " step path: '" + path + "'");
	    }      
	    
	    // if is a global graph, check that it is a child of the root graph
	    if (subgraphCallerStep.getIsGlobal() && !path.equals("")) {
	        Utilities.error("Graph " + xmlFileName
	                + " is not the root graph, but contains a <globalSubgraph> step '"
	                + subgraphCallerStep.getBaseName() +"'.  They are only allowed in the root graph.");
	    }
	    
	    // parse it
	    WorkflowXmlParser<T> parser = new WorkflowXmlParser<T>();
	    WorkflowGraph<T> subgraph =
		parser.parseWorkflow(workflow, stepClass, subgraphXmlFileName,
				     globalSteps, globalConstants, 
				     subgraphCallerStep.getIsGlobal()); 

            // set the path of its unexpanded steps
            String newPath = path + subgraphCallerStep.getBaseName() + ".";
            subgraph.setPath(newPath);

	    // set the calling step of its unexpanded steps
	    subgraph.setCallingStep(subgraphCallerStep);

            // instantiate param values from calling step
            subgraph.instantiateValues(subgraphCallerStep.getBaseName(),
                    xmlFileName, globalConstants,
                    subgraphCallerStep.getParamValues(), paramErrorsMap);


            // expand it (recursively) 
            // (this includes setting the paths of the expanded steps)
	    List<String> newXmlFileNamesStack = new ArrayList<String>(xmlFileNamesStack);
	    newXmlFileNamesStack.add(subgraphXmlFileName);
            subgraph.expandSubgraphs(newPath, newXmlFileNamesStack, stepClass, paramErrorsMap, globalSteps, globalConstants); 
            
            // insert it
            WorkflowStep subgraphReturnStep = subgraphCallerStep.getChildren().get(0);
            subgraphCallerStep.removeChild(subgraphReturnStep);
            subgraphReturnStep.removeParent(subgraphCallerStep);
            subgraph.attachToCallingStep(subgraphCallerStep);
            subgraph.attachToReturnStep(subgraphReturnStep);
            
            // add its steps to stepsByName
            for (T subgraphStep : subgraph.getSteps()) {
                stepsByName.put(subgraphStep.getFullName(), subgraphStep);
            }
        }
    }
    
    private void setPath(String path) {
        for (T step : getSteps()) step.setPath(path);
    }
    
    private void setCallingStep(T callingStep) {
        for (T step : getSteps()) step.setCallingStep(callingStep);
    }
    
    // attach the roots of this graph to a step in a parent graph that is
    // calling it
    private void attachToCallingStep(WorkflowStep callingStep) {
        for (T rootStep : rootSteps) {
            callingStep.addChild(rootStep);
            rootStep.addParent(callingStep);
        }
    }
    
    // attach the leafs of this graph to a step in a parent graph that is
    // the return from this graph
    private void attachToReturnStep(WorkflowStep childStep) {
        for (T leafStep : leafSteps) {
            childStep.addParent(leafStep);
            leafStep.addChild(childStep);
        }
    }
/*    
    private void initializeGlobalSteps() throws NoSuchAlgorithmException, Exception {
        for (T step : getSteps()) {
            if (step.getIsGlobal()) {
                String stepDigest = step.getParamsDigest();
                if (!globalSteps.containsKey(stepDigest)) {
                    globalSteps.put(stepDigest, new ArrayList<T>());
                }
                List<T> sharedGlobalSteps = globalSteps.get(stepDigest);
                sharedGlobalSteps.add(step);
                step.setSharedGlobalSteps(sharedGlobalSteps);
            }
        }
        
    }
    */

    ////////////////////////////////////////////////////////////////////////
    //    Invert 
    ////////////////////////////////////////////////////////////////////////
    @SuppressWarnings("unchecked")
    void convertToUndo() throws FileNotFoundException, SQLException, IOException {
        
        // find all descendents of the undo root
        WorkflowStep undoRootStep = stepsByName.get(workflow.getUndoStepName());
        Set<WorkflowStep> undoDescendents = undoRootStep.getDescendents();
	undoDescendents.add(undoRootStep);

	// reset stepsByName to hold only descendents of undo root that are DONE
        stepsByName = new HashMap<String,T>();
        for (WorkflowStep step : undoDescendents) {
            if (step.getState().equals(Workflow.DONE))
		stepsByName.put(step.getFullName(), (T)step);
        }

        // invert each step (in trimmed graph)
        for (T step : getSteps()) step.invert(stepsByName.keySet());
 
	// remove undoRootStep's children (it is the new leaf)
	undoRootStep.removeAllChildren();
        
	// reset root and leaf sets
	setRootsAndLeafs();

        // make sure all undoable steps in db have state set
        PreparedStatement undoStepPstmt = WorkflowStep.getPreparedUndoUpdateStmt(workflow.getDbConnection(), workflow.getId()); 
        try {
            for (WorkflowStep step : getSteps()) {
                undoStepPstmt.setString(1, step.getFullName());
                undoStepPstmt.execute();
            }
        } finally {
            undoStepPstmt.close();;
        }
    }

    ////////////////////////////////////////////////////////////////////////
    //    Manage DB 
    ////////////////////////////////////////////////////////////////////////

    // check if the in-memory graph matches that in the db exactly
    boolean inDbExactly() throws SQLException, FileNotFoundException, NoSuchAlgorithmException, IOException, Exception {
	String sql = "select name, params_digest, depth_first_order, step_class, state"
	    + " from apidb.workflowstep"  
	    + " where workflow_id = " + workflow.getId()
	    + " order by depth_first_order";

	Statement stmt = null;
	ResultSet rs = null;
	try {
	    stmt = workflow.getDbConnection().createStatement();
	    rs = stmt.executeQuery(sql);
	    for (T step : getSortedSteps()) {
		if (!rs.next()) return false;
		String dbName = rs.getString(1);
		String dbDigest = rs.getString(2);
		int dbDepthFirstOrder = rs.getInt(3);
		String dbClassName = rs.getString(4);
		String dbState = rs.getString(5);

		boolean stepClassMatch = 
		    (dbClassName == null && step.getStepClassName() == null)
		    || ((dbClassName != null && step.getStepClassName() != null)
			&& step.getStepClassName().equals(dbClassName));

		boolean mismatch = !step.getFullName().equals(dbName)
		    || !step.getParamsDigest().equals(dbDigest)
		    || !stepClassMatch
		  || step.getDepthFirstOrder() != dbDepthFirstOrder;

		if (mismatch) {
		    if (!dbState.equals(Workflow.READY) 
			&& !dbState.equals(Workflow.ON_DECK)
			&& !dbState.equals(Workflow.FAILED)
			) {
			Utilities.error("Step '" + dbName +"' has changed in the XML file illegally. Changes not allowed while in the state '" + dbState + "'" + nl
					+ "old name:              " + dbName + nl
					+ "old params digest:     " + dbDigest + nl
                                        + "old depth first order: " + dbDepthFirstOrder + nl
					+ "old class name:        " + dbClassName + nl
					+ nl
                                        + "new name:              " + step.getFullName() + nl
                                        + "new params digest:     " + step.getParamsDigest() + nl
					+ "new depth first order: " + step.getDepthFirstOrder() + nl
					+ "new class name:        " + step.getStepClassName());
		    }
		    return false;
		}
	    }
	    if (rs.next()) return false;
	} finally {
	    if (rs != null) rs.close();
	    if (stmt != null) stmt.close(); 
	}  
	return true;
    }

    // remove from the db all READY or ON_DECK steps
    void removeReadyStepsFromDb() throws SQLException, FileNotFoundException, IOException {
	String sql = "delete from apidb.workflowstep where workflow_id = "
	    + workflow.getId() + 
	    " and (state = 'READY' or state = 'ON_DECK')";
	workflow.executeSqlUpdate(sql);
    }

    Set<String> getStepNamesInDb() throws SQLException, FileNotFoundException, IOException {
	Set<String> stepsInDb = new HashSet<String>();

	String sql = "select name"
	    + " from apidb.workflowstep"  
	    + " where workflow_id = " + workflow.getId()
	    + " order by depth_first_order";

	Statement stmt = null;
	ResultSet rs = null;
	try {
	    stmt = workflow.getDbConnection().createStatement();
	    rs = stmt.executeQuery(sql);
	    while (rs.next()) {
		String dbName = rs.getString(1);
		stepsInDb.add(dbName);
	    }
	} finally {
	    if (rs != null) rs.close();
	    if (stmt != null) stmt.close(); 
	}  
	return stepsInDb;
    }
    
    ////////////////////////////////////////////////////////////////////////
    //     Static methods
    ////////////////////////////////////////////////////////////////////////
    
    static <S extends WorkflowStep > WorkflowGraph<S> constructFullGraph(Class<S> stepClass,
            Workflow<S> workflow) throws FileNotFoundException, SAXException, IOException, Exception {
        
        // create structures to hold global steps and constants
        Map<String, S> globalSteps = new HashMap<String, S>();
        Map<String,String> globalConstants = new LinkedHashMap<String,String>();
        
        // create root graph
        WorkflowXmlParser<S> parser = new WorkflowXmlParser<S>();
	WorkflowGraph<S> rootGraph =
		parser.parseWorkflow(workflow, stepClass, workflow.getWorkflowXmlFileName(),
		        globalSteps, globalConstants, false); 

	// construct map that will accumulate error messages
	Map<String,Map<String,List<String>>> paramErrorsMap =
	    new HashMap<String,Map<String,List<String>>>();
	
	// instantiate param values from root params file
        rootGraph.instantiateValues("root",
                                    workflow.getWorkflowXmlFileName(),
                                    globalConstants,
                                    getRootGraphParamValues(workflow),
				    paramErrorsMap);
        
        // expand subgraphs
	List<String> xmlFileNamesStack = new ArrayList<String>();
	xmlFileNamesStack.add(workflow.getWorkflowXmlFileName());
        rootGraph.expandSubgraphs("", xmlFileNamesStack, stepClass, paramErrorsMap,
                globalSteps, globalConstants);
        
        // report param errors, if any
        if (paramErrorsMap.size() != 0) {
	    StringBuffer buf = new StringBuffer();
	    for (String file : paramErrorsMap.keySet()) {
		buf.append(nl + "  File " + file + ":" + nl);
		for (String step : paramErrorsMap.get(file).keySet()) {
		    buf.append("      step: " + step + nl);
		    for (String param : paramErrorsMap.get(file).get(step)) 
			buf.append("          > " + param + nl);
		}
	    }
			
            Utilities.error("Graph \"compilation\" failed.  The following subgraph parameter values are missing:" + nl + buf);
        }
        
	// delete excluded steps
	rootGraph.deleteExcludedSteps();

        // initialize global steps
        // rootGraph.initializeGlobalSteps();
        
        return rootGraph;
    }   
    
    @SuppressWarnings("unchecked")
    static <S extends WorkflowStep > Map<String,String>getRootGraphParamValues(Workflow<S> workflow) throws FileNotFoundException, IOException {
        Properties paramValues = new Properties();
        paramValues.load(new FileInputStream(workflow.getHomeDir() + "/config/rootParams.prop"));
        Map<String,String>map = new HashMap<String,String>();
        Enumeration<String> e = (Enumeration<String>) paramValues.propertyNames();
        while(e.hasMoreElements()) {
            String k = e.nextElement();
            map.put(k,paramValues.getProperty(k));
        }
        return map;
    }
    
}
