package org.gusdb.workflow;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.sql.Date;
import java.sql.ResultSet;
import java.sql.SQLException;

    /*

  lite workflow object (a handle on workflow row in db) used in three contexts:
    - quick reporting of workflow state
    - reseting the workflow
    - workflowstep UI command changing state of a step

   (it avoids the overhead and stringency of parsing and validating
    all workflow steps)
    */

public class WorkflowHandle extends WorkflowBase {
    
 
    public WorkflowHandle() {
    }

}

