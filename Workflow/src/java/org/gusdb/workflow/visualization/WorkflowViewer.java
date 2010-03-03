package org.gusdb.workflow.visualization;

import edu.uci.ics.jung.algorithms.layout.Layout;
import edu.uci.ics.jung.algorithms.layout.TreeLayout;
import edu.uci.ics.jung.graph.Graph;
import edu.uci.ics.jung.graph.DelegateForest;
import edu.uci.ics.jung.graph.DirectedSparseGraph;
import edu.uci.ics.jung.graph.Forest;
import edu.uci.ics.jung.visualization.VisualizationViewer;
import edu.uci.ics.jung.visualization.GraphZoomScrollPane;
import edu.uci.ics.jung.visualization.control.CrossoverScalingControl;
import edu.uci.ics.jung.visualization.control.PluggableGraphMouse;
import edu.uci.ics.jung.visualization.control.PickingGraphMousePlugin;
import edu.uci.ics.jung.visualization.control.ScalingGraphMousePlugin;
import edu.uci.ics.jung.visualization.renderers.Renderer.VertexLabel.Position;

import java.io.IOException;

import java.awt.BasicStroke;
import java.awt.Color;
import java.awt.Dimension;
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

import org.gusdb.workflow.*;

public class WorkflowViewer extends JFrame implements ActionListener {
    private Workflow workflow;
    private WorkflowGraph<WorkflowStep> currentGraph;
    private WorkflowXmlParser<WorkflowStep> parser;
    private Forest<WorkflowStep,Integer> workflowTree;
    private Stack<WorkflowGraph> history;
    private Map<String, WorkflowStep> globalSteps;
    private Map<String,String> globalConstants;
    private JLabel current;
    private JButton back;
    private JPanel applicationPane;
    private JPanel graphPane;

    public WorkflowViewer() throws IOException {
	super("Workflow Viewer");
	//Create a file chooser
	final JFileChooser fc = new JFileChooser();
	this.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
	this.setVisible(true);
	fc.setFileSelectionMode(JFileChooser.DIRECTORIES_ONLY);
	
	//In response to a button click:
	int returnVal = fc.showOpenDialog(this);
	
	if (returnVal == JFileChooser.APPROVE_OPTION) {
	    parser = new WorkflowXmlParser<WorkflowStep>();
	    history = new Stack<WorkflowGraph>();
	    workflow = new Workflow<WorkflowStep>(fc.getSelectedFile().getCanonicalPath());

	    initApplicationPane();
	    createViewFromXmlFile(workflow.getWorkflowXmlFileName());
	}
    }
    
    public void actionPerformed(ActionEvent e) {
	loadPreviousGraphView();
    }
    
    protected void createViewFromXmlFile(String xmlFileName) {
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
	Layout layout = new TreeLayout(workflowTree, 375, 175);
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
	
	PluggableGraphMouse gm = new PluggableGraphMouse();
	gm.add(new ScalingGraphMousePlugin(new CrossoverScalingControl(), 0, 1.1f, 0.9f));
	gm.add(new WorkflowViewerMousePlugin(this));
	gm.add(new PickingGraphMousePlugin());
	
	vv.setGraphMouse(gm);
	
	graphPane.removeAll();
	graphPane.add(new GraphZoomScrollPane(vv));
	this.validate();
	this.pack();
    }

    private void buildDisplayTree() {
	    // Graph where WorkflowStep is the type of the vertices and Integer is the type of the edges
	    workflowTree = new DelegateForest<WorkflowStep,Integer>(new DirectedSparseGraph<WorkflowStep,Integer>());
	    
	    int edge = 0;
	    // Iterate over steps in graph, adding to graph & adding edges based on parent pointers
	    List<WorkflowStep> steps = currentGraph.getSortedSteps();
	    for (WorkflowStep step : steps) {
		workflowTree.addVertex(step);

		List<WorkflowStep> parents = step.getParents();
		for (WorkflowStep parent : parents) {
		    workflowTree.addEdge(new Integer(edge++),parent,step);
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
	c.gridx = 1;
	c.gridy = 0;
	c.weightx = 0.6;
	applicationPane.add(current, c);

	graphPane = new JPanel();
	c.fill = GridBagConstraints.BOTH;
	c.anchor = GridBagConstraints.SOUTHEAST;
	c.gridx = 0;
	c.gridy = 1;
	c.weighty = 1;
	c.gridwidth = 2;
	applicationPane.add(graphPane, c);

	this.add(applicationPane);
    }

    public static void main(String[] args) {
	try {
	    new WorkflowViewer();
	}
	catch (Exception ex) {
	    // TODO: Don't do this.
	    ex.printStackTrace();
	    System.exit(1);
	}
    }
} 
