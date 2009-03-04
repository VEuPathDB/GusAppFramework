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
import java.sql.Connection;
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
           - insert it into parent graph
              - attach its root and leaf steps to parent graph
 *   
 *  (3) in a final pass, set the path of each of the steps (top down recursion)
 * 
 * 
 */

public class WorkflowGraph<T extends WorkflowStep> {
    private List<String> paramDeclarations = new ArrayList<String>();
    private Map<String,String> constants = new LinkedHashMap<String,String>();
    Workflow<T> workflow;
    String xmlFileName;
    String name;
    
    Map<T, String> stepsWithSubgraph = new HashMap<T, String>(); 
    private List<T> rootSteps = new ArrayList<T>();
    
    // following state must be updated after expansion
    Map<String, T> stepsByName = new HashMap<String, T>();
    private List<T> leafSteps = new ArrayList<T>();    
    List<T> sortedSteps; 
    private Map<String, List<T>> globalSteps = new HashMap<String, List<T>>();
    
    final static String nl = System.getProperty("line.separator");

    public WorkflowGraph() {}

    public void addConstant(NamedValue constant) {
	constants.put(constant.getName(),constant.getValue());
    }
    
    public void addParamDeclaration(Name paramName) {
	paramDeclarations.add(paramName.getName());
    }
    
    public void setName(String name) {
	this.name = name;
    }

    public void addStep(T step) throws FileNotFoundException, IOException {
        step.setWorkflowGraph(this);
        String stepName = step.getBaseName();
        if (stepsByName.containsKey(stepName))
            Utilities.error("In graph " + name + ", non-unique step name: '" + stepName + "'");
        stepsByName.put(stepName, step);
    }
    
    void setWorkflow(Workflow<T> workflow) {
        this.workflow = workflow;
    }
    
    Workflow<T> getWorkflow() {
        return workflow;
    }

    void setXmlFileName(String xmlFileName) {
     this.xmlFileName = xmlFileName;
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
    
    // clean up after building from xml
    void postprocessSteps() throws FileNotFoundException, IOException {
        
        for (T step : getSteps()) {

	    // make the parent/child links from the remembered dependencies
            for (Name dependName : step.getDependsNames()) {
                String stepName = step.getBaseName();
                T parent = stepsByName.get(dependName.getName());
                if (parent == null) 
                    Utilities.error("In file " + xmlFileName + ", step '"
				    + stepName + "' depends on step '"
                          + dependName.getName() + "' which is not found");
                step.addParent(parent);
                parent.addChild(step);
            }
            
            // keep track of all subgraph xml files
            String sgxfn = step.getSubgraphXmlFileName();
            if (sgxfn != null) {
                stepsWithSubgraph.put(step, sgxfn);
            }

	    // validate loadType
	    step.checkLoadTypes();
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
        for (T step : getSteps()) {
            if (step.getParents().size() == 0) rootSteps.add(step);
            if (step.getChildren().size() == 0) leafSteps.add(step);
        }       
    }
    
    public String toString() {
        return "Constants" + nl + constants.toString() + nl + nl
        + "Steps" + nl + getSortedSteps().toString();
    }
    

    @SuppressWarnings("unchecked")
    private void instantiateValues(String stepBaseName, String xmlFileName,
            Map<String,String> paramValues,
            Map<String,Map<String,List<String>>> paramErrorsMap) {
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
            step.substituteValues(constants, false);
            step.substituteValues(paramValues, true);
	    step.setIfs();
        }

	
    }
    /////////////////////////////////////////////////////////////////////////
    //   subgraph expansion
    /////////////////////////////////////////////////////////////////////////
    private void expandSubgraphs(String path, List<String> callingXmlFileNames,
            Class<T> stepClass, Map<String,Map<String,List<String>>> paramErrorsMap) throws SAXException, Exception {
        for (T stepWithSubgraph : stepsWithSubgraph.keySet()) {
        
            // get a graph to insert
            String subgraphXmlFileName = stepsWithSubgraph.get(stepWithSubgraph);
	    if (callingXmlFileNames.contains(subgraphXmlFileName)) {
		throw new Exception("Circular reference to graphXmlFile '"
				    + subgraphXmlFileName + "'"
				    + " step path: '" + path + "'");
	    }      
	    WorkflowXmlParser<T> parser = new WorkflowXmlParser<T>();
	    WorkflowGraph<T> subgraph =
		parser.parseWorkflow(workflow, stepClass, subgraphXmlFileName); 

            // set the path of its unexpanded steps
            String newPath = path + stepWithSubgraph.getBaseName() + ".";
            subgraph.setPath(newPath);

            // set include/exclude based on calling step, if set there
            subgraph.setIncludeExcludeFromCaller(stepWithSubgraph);
            
            // instantiate param values from calling step
            subgraph.instantiateValues(stepWithSubgraph.getBaseName(),
                    xmlFileName,
                    stepWithSubgraph.getParamValues(), paramErrorsMap);


            // expand it (recursively) 
            // (this includes setting the paths of the expanded steps)
	    List<String> callingXmlFileNamesNew = new ArrayList<String>(callingXmlFileNames);
	    callingXmlFileNamesNew.add(subgraphXmlFileName);
            subgraph.expandSubgraphs(newPath, callingXmlFileNamesNew, stepClass, paramErrorsMap); 
            
            // insert it
            WorkflowStep subgraphReturnStep = stepWithSubgraph.getChildren().get(0);
            stepWithSubgraph.removeChild(subgraphReturnStep);
            subgraphReturnStep.removeParent(stepWithSubgraph);
            subgraph.attachToCallingStep(stepWithSubgraph);
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
    
    private void setIncludeExcludeFromCaller(T caller) {
        String includeIf_str = caller.getIncludeIfString();
        String excludeIf_str = caller.getExcludeIfString();
        if (includeIf_str != null && includeIf_str.equals("false")) { 
            for (T step: getSteps()) step.setCallerIncludeIf(includeIf_str);
        }
        if (excludeIf_str != null && excludeIf_str.equals("true")) { 
            for (T step: getSteps()) step.setCallerExcludeIf(excludeIf_str);
        }
    }
    
    // attach the roots of this graph to a step in a parent graph that is
    // calling it
    private void attachToCallingStep(WorkflowStep parentStep) {
        for (T rootStep : rootSteps) {
            parentStep.addChild(rootStep);
            rootStep.addParent(parentStep);
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

    ////////////////////////////////////////////////////////////////////////
    //    Invert 
    ////////////////////////////////////////////////////////////////////////
    @SuppressWarnings("unchecked")
    void convertToUndo() throws FileNotFoundException, SQLException, IOException {
        
        // invert each step
        for (T step : getSteps()) step.invert();
        
        // trim away steps that are not involved in undo
        WorkflowStep undoRootStep = stepsByName.get(workflow.getUndoStepName());
        Set<WorkflowStep> allUndoKids = undoRootStep.getAllChildren();
        stepsByName = new HashMap<String,T>();
        for (WorkflowStep step : allUndoKids) {
            stepsByName.put(step.getFullName(), (T)step);
        }
        
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
        
	WorkflowXmlParser<S> parser = new WorkflowXmlParser<S>();
	WorkflowGraph<S> rootGraph =
		parser.parseWorkflow(workflow, stepClass, workflow.getStepsXmlFileName()); 

	Map<String,Map<String,List<String>>> paramErrorsMap =
	    new HashMap<String,Map<String,List<String>>>();
        rootGraph.instantiateValues("root",
                                    "rootParams.prop",
				    getRootGraphParamValues(workflow),
				    paramErrorsMap);
        
        // expand subgraphs
	List<String> callingXmlFileNames = new ArrayList<String>();
	callingXmlFileNames.add(workflow.getStepsXmlFileName());
        rootGraph.expandSubgraphs("", callingXmlFileNames, stepClass, paramErrorsMap);
        
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
