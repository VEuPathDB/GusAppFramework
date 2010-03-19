package org.gusdb.workflow.visualization;

import edu.uci.ics.jung.algorithms.layout.FRLayout;
import edu.uci.ics.jung.graph.DirectedGraph;
import edu.uci.ics.jung.graph.DirectedSparseGraph;
import edu.uci.ics.jung.visualization.VisualizationViewer;
import edu.uci.ics.jung.visualization.GraphZoomScrollPane;
import edu.uci.ics.jung.visualization.control.CrossoverScalingControl;
import edu.uci.ics.jung.visualization.control.PluggableGraphMouse;
import edu.uci.ics.jung.visualization.control.PickingGraphMousePlugin;
import edu.uci.ics.jung.visualization.control.ScalingGraphMousePlugin;
import edu.uci.ics.jung.visualization.renderers.Renderer.VertexLabel.Position;

import java.io.IOException;

import java.awt.BasicStroke;
import java.awt.BorderLayout;
import java.awt.Color;
import java.awt.Dimension;
import java.awt.Font;
import java.awt.GridBagConstraints;
import java.awt.GridBagLayout;
import java.awt.Paint;
import java.awt.Rectangle;
import java.awt.Shape;
import java.awt.Stroke;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;

import javax.swing.JButton;
import javax.swing.JFileChooser;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JOptionPane;
import javax.swing.JPanel;

import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Stack;

import org.apache.commons.collections15.Transformer;

import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.Option;
import org.apache.commons.cli.OptionGroup;
import org.apache.commons.cli.Options;

import org.gusdb.workflow.Utilities;
import org.gusdb.workflow.Workflow;
import org.gusdb.workflow.WorkflowGraph;
import org.gusdb.workflow.WorkflowStep;
import org.gusdb.workflow.WorkflowXmlParser;

import org.gusdb.workflow.visualization.layout.AssistedTreeLayout;
import org.gusdb.workflow.visualization.mouse.PopupVertexEdgeMenuMousePlugin;
import org.gusdb.workflow.visualization.mouse.WorkflowViewerMousePlugin;

public class WorkflowViewer extends JFrame implements ActionListener {
    final static String nl = System.getProperty("line.separator");
    private static final String TITLE = "Workflow Viewer";
    private Workflow workflow;
    private WorkflowGraph<WorkflowStep> currentGraph;
    private WorkflowXmlParser<WorkflowStep> parser;
    private DirectedGraph<WorkflowStep,Integer> currentView;
    private Stack<WorkflowGraph> history;
    private Map<String, WorkflowStep> globalSteps;
    private Map<String,String> globalConstants;
    private JLabel current;
    private JButton back;
    private JPanel applicationPane;
    private JPanel graphPane;
    private JFrame menuFrame;

    public WorkflowViewer(String workflowDir) throws IOException {
	super(TITLE);
	initApplicationPane();
	parser = new WorkflowXmlParser<WorkflowStep>();
	history = new Stack<WorkflowGraph>();
	workflow = new Workflow<WorkflowStep>(workflowDir);
	createViewFromXmlFile(workflow.getWorkflowXmlFileName());
    }

    public void actionPerformed(ActionEvent e) {
	loadPreviousGraphView();
    }
    
    public void createViewFromXmlFile(String xmlFileName) {
	try {
	    // create structures to hold global steps and constants
	    // at some point, may want to only create them once & maintain as class fields
	    globalSteps = new HashMap<String, WorkflowStep>();
	    globalConstants = new LinkedHashMap<String,String>();
	    
	    if (currentGraph != null) {
		history.push(currentGraph);
	    }

	    // create root graph for this workflow
	    Class<WorkflowStep> stepClass = WorkflowStep.class;
	    currentGraph = parser.parseWorkflow(workflow, stepClass,
						xmlFileName,
						globalSteps, globalConstants, false, false);
	    updateGraphView();
	}
	catch (Exception ex) {
	    //TODO:  Don't do this.
	    ex.printStackTrace();
	    System.exit(1);
	}
    }

    private void updateGraphView() {
	buildDisplayTree();
	
	current.setText(currentGraph.getXmlFileName());

	// The Layout is parameterized by the vertex and edge types
	//FRLayout<WorkflowStep,Integer> layout = new FRLayout<WorkflowStep,Integer>(currentView, new Dimension(currentView.getVertexCount() * 150, currentView.getVertexCount() * 50));
	//layout.setAttractionMultiplier(0.5);
	//layout.setRepulsionMultiplier(0.75);
	//layout.setMaxIterations(400);

	AssistedTreeLayout<WorkflowStep,Integer> layout = new AssistedTreeLayout<WorkflowStep,Integer>(currentView, 350, 150);

	// sets the initial size of the layout space
	// The VisualizationViewer is parameterized by the vertex and edge types
	VisualizationViewer vv = new VisualizationViewer(layout);
	vv.setPreferredSize(new Dimension(1024,768));

	Transformer<WorkflowStep,Shape> shaper = new Transformer<WorkflowStep,Shape>() {
	    public Shape transform(WorkflowStep vertex) {
		return new Rectangle(300,100);
	    }
	};
	vv.getRenderContext().setVertexShapeTransformer(shaper);
	
	Transformer<WorkflowStep,String> labeler = new Transformer<WorkflowStep,String>() {
	    public String transform(WorkflowStep vertex) {
		return vertex.getBaseName();
	    }
	};
	vv.getRenderContext().setVertexLabelTransformer(labeler);
	
	Transformer<WorkflowStep,Font> fontStyler = new Transformer<WorkflowStep,Font>() {
	    public Font transform(WorkflowStep vertex) {
		return new Font("Lucida Sans Regular", Font.PLAIN, 15);
	    }
	};
	vv.getRenderContext().setVertexFontTransformer(fontStyler);
	
	Transformer<WorkflowStep,Paint> painter = new Transformer<WorkflowStep,Paint>() {
	    public Paint transform(WorkflowStep vertex) {
		return Color.WHITE;
	    }
	};
	vv.getRenderContext().setVertexFillPaintTransformer(painter);

	Transformer<WorkflowStep,Stroke> outliner = new Transformer<WorkflowStep,Stroke>() {
	    public Stroke transform(WorkflowStep vertex) {
		if (vertex.getIsSubgraphCall()) {
		    return new BasicStroke(3f);
		}
		return new BasicStroke(1f);
	    }
	};
	vv.getRenderContext().setVertexStrokeTransformer(outliner);
	
	vv.getRenderer().getVertexLabelRenderer().setPosition(Position.CNTR);
	
	// Step details popup is disabled for now.
	//PopupVertexEdgeMenuMousePlugin mousePlugin = new PopupVertexEdgeMenuMousePlugin();
	//mousePlugin.setVertexPopup(new MyMouseMenus.WorkflowStepMenu(menuFrame));

	PluggableGraphMouse gm = new PluggableGraphMouse();
	gm.add(new ScalingGraphMousePlugin(new CrossoverScalingControl(), 0, 1.1f, 0.9f));
	gm.add(new WorkflowViewerMousePlugin(this));
	//gm.add(mousePlugin);
	gm.add(new PickingGraphMousePlugin());
	
	vv.setGraphMouse(gm);

	graphPane.removeAll();
	graphPane.add(new GraphZoomScrollPane(vv),BorderLayout.CENTER);
	this.validate();
	this.pack();
    }

    private void buildDisplayTree() {
	// Graph where WorkflowStep is the type of the vertices and Integer is the type of the edges
	currentView = new DirectedSparseGraph<WorkflowStep,Integer>();
	    
	int edge = 0;
	// Iterate over steps in graph, adding to graph & adding edges based on parent pointers
	List<WorkflowStep> steps = currentGraph.getSortedSteps();
	for (WorkflowStep step : steps) {
	    currentView.addVertex(step);

	    List<WorkflowStep> parents = step.getParents();
	    for (WorkflowStep parent : parents) {
		currentView.addEdge(new Integer(edge++),parent,step);
	    }
	}
    }
    
    private void loadPreviousGraphView() {
	if (history.size() > 0) {
	    currentGraph = history.pop();
	    updateGraphView();
	}
	else {
	    JOptionPane.showMessageDialog(this, "You are already looking at the first workflow graph.");
	}
    }

    private void initApplicationPane() {
	applicationPane = new JPanel(new GridBagLayout());
	GridBagConstraints c = new GridBagConstraints();

	back = new JButton("Back");
	back.addActionListener(this);
	c.fill = GridBagConstraints.HORIZONTAL;
	c.gridx = 0;
	c.gridy = 0;
	c.weighty = 0;
	applicationPane.add(back, c);

	current = new JLabel();
	c.fill = GridBagConstraints.HORIZONTAL;
	c.anchor = GridBagConstraints.CENTER;
	c.gridx = 1;
	c.gridy = 0;
	c.weightx = 0.6;
	applicationPane.add(current, c);

	graphPane = new JPanel(new BorderLayout());
	graphPane.setMinimumSize(new Dimension(800,600));
	c.fill = GridBagConstraints.BOTH;
	c.anchor = GridBagConstraints.SOUTHEAST;
	c.gridx = 0;
	c.gridy = 1;
	c.weighty = 1;
	c.gridwidth = 2;
	applicationPane.add(graphPane, c);

	menuFrame = new JFrame();

	this.add(applicationPane);
	this.setPreferredSize(new Dimension(800,600));
	this.setVisible(true);
    }

    public static void main(String[] args) {
	String cmdName = System.getProperty("cmdName");

	// parse command line
	Options options = declareOptions();
	String cmdlineSyntax = cmdName + " -h workflow_home_dir";
	String cmdDescrip = "View a workflow graph.";
	CommandLine cmdLine =
	    Utilities.parseOptions(cmdlineSyntax, cmdDescrip, getUsageNotes(), options, args);
	 
	String homeDirName = cmdLine.getOptionValue("h");
	try {
	    new WorkflowViewer(homeDirName);
	}
	catch (Exception ex) {
	    Utilities.usage(cmdlineSyntax, cmdDescrip, getUsageNotes(), options);
	    System.exit(1);
	}
    }

    private static Options declareOptions() {
	Options options = new Options();

	Utilities.addOption(options, "h", "Workflow homedir (see below)", true);      

	return options;
    }

    private static String getUsageNotes() {
	return

	    nl 
	    + "Home dir must contain the following:" + nl
	    + "   config/" + nl
	    + "     initOfflineSteps   (steps to take offline at startup)" + nl
	    + "     loadBalance.prop   (configure load balancing)" + nl
	    + "     rootParams.prop    (root parameter values)" + nl
	    + "     stepsGlobal.prop   (global steps config)" + nl
	    + "     steps.prop         (steps config)" + nl
	    + "     workflow.prop      (meta config)" + nl
	    + nl + nl   
	    + nl + nl                        
	    + "Examples:" + nl
	    + nl     
	    + "  view a workflow:" + nl
	    + "    % workflowViewer -h workflow_dir" + nl;
    }
} 
