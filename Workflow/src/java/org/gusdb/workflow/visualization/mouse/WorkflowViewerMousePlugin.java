package org.gusdb.workflow.visualization.mouse;

import edu.uci.ics.jung.algorithms.layout.Layout;
import edu.uci.ics.jung.algorithms.layout.GraphElementAccessor;
import edu.uci.ics.jung.visualization.control.AbstractGraphMousePlugin;
import edu.uci.ics.jung.visualization.VisualizationViewer;

import java.awt.Cursor;
import java.awt.geom.Point2D;
import java.awt.event.InputEvent;
import java.awt.event.MouseEvent;
import java.awt.event.MouseListener;
import java.awt.event.MouseMotionListener;

import javax.swing.JComponent;

import org.gusdb.workflow.WorkflowStep;
import org.gusdb.workflow.visualization.WorkflowViewer;

public class WorkflowViewerMousePlugin extends AbstractGraphMousePlugin
    implements MouseListener, MouseMotionListener {
    private WorkflowViewer viewer;

    public WorkflowViewerMousePlugin(WorkflowViewer viewer) {
	this(InputEvent.BUTTON1_MASK, viewer);
    }

    public WorkflowViewerMousePlugin(int selectionModifiers, WorkflowViewer viewer) {
        super(selectionModifiers);
	this.viewer = viewer;
    }

    public void mousePressed(MouseEvent e) {
    }

    public void mouseReleased(MouseEvent e) {
    }

    public void mouseDragged(MouseEvent e) {
    }

    public void mouseClicked(MouseEvent e) {
	WorkflowStep vertex = null;
	if (e.getClickCount() > 1) {
	    down = e.getPoint();
	    VisualizationViewer<WorkflowStep,Integer> vv = (VisualizationViewer)e.getSource();
	    GraphElementAccessor<WorkflowStep,Integer> pickSupport = vv.getPickSupport();
	    if(pickSupport != null) {
		Layout<WorkflowStep,Integer> layout = vv.getGraphLayout();

		vertex = pickSupport.getVertex(layout, e.getPoint().getX(), e.getPoint().getY());
		if(vertex != null) {
		    if (vertex.getIsSubgraphCall()) {
			viewer.displayGraph(WorkflowViewer.getSubgraphKey(vertex));
		    }
		    e.consume();
		}
	    }
	}
    }

    public void mouseEntered(MouseEvent e) {
    }

    public void mouseExited(MouseEvent e) {
    }

    public void mouseMoved(MouseEvent e) {
    }

}
