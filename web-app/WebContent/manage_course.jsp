<%@page import="db.DBConnection"%>
<%@page import="sql.User"%>
<%@page import="sql.Section"%>
<%@page import="java.util.*"%>
<%@page import="helper.*"%>
<jsp:useBean id="dbaccess" class="db.DBAccess" scope="session" />
<jsp:useBean id="usersession" class="helper.UserSession" scope="session" />
<!doctype html>
<html lang="en">
<head>
	<meta http-equiv="Content-Type" content="text/html" charset="utf-8" />
	<meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
	<meta name="viewport" content="width=device-width, initial-scale=1.0">
	<title>Seneca | Subjects</title>
	<link rel="icon" href="http://www.cssreset.com/favicon.png">
	<link rel="stylesheet" type="text/css" media="all" href="css/fonts.css">
	<link rel="stylesheet" type="text/css" media="all" href="css/themes/base/style.css">
	<link rel="stylesheet" type="text/css" media="all" href="css/themes/base/jquery.ui.core.css">
	<link rel="stylesheet" type="text/css" media="all" href="css/themes/base/jquery.ui.theme.css">
	<link rel="stylesheet" type="text/css" media="all" href="css/themes/base/jquery.ui.selectmenu.css">
	<script type="text/javascript" src="js/jquery-1.9.1.js"></script>
	<script type="text/javascript" src="js/modernizr.custom.79639.js"></script>
	<script type="text/javascript" src="js/ui/jquery.ui.core.js"></script>
	<script type="text/javascript" src="js/ui/jquery.ui.widget.js"></script>
	<script type="text/javascript" src="js/ui/jquery.ui.position.js"></script>
	<script type="text/javascript" src="js/ui/jquery.ui.selectmenu.js"></script>
	<script type="text/javascript" src="js/ui/jquery.ui.stepper.js"></script>
	<script type="text/javascript" src="js/ui/jquery.ui.dataTable.js"></script>
	<script type="text/javascript">
    //Table
	$(screen).ready(function() {
	
	    /* Course List */	    
	    $('#courseList').dataTable({"sPaginationType": "full_numbers"});
	    $('#courseList').dataTable({"aoColumnDefs": [{ "bSortable": false, "aTargets":[5]}], "bRetrieve": true, "bDestroy": true});
	    $.fn.dataTableExt.sErrMode = 'throw';
	    $('.dataTables_filter input').attr("placeholder", "Filter entries");
	    $(".remove").click(function(){
	        return window.confirm("Remove this item from list?");
	    });   
	});
	/* SELECT BOX */
	$(function(){
	    $('select').selectmenu();
	});
	</script>
<%
    //Start page validation
    String userId = usersession.getUserId();
    GetExceptionLog elog = new GetExceptionLog();
    if (userId.equals("")) {
    	session.setAttribute("redirecturl", request.getRequestURI()+(request.getQueryString()!=null?"?"+request.getQueryString():""));
        response.sendRedirect("index.jsp?message=Please log in");
        return;
    }
    if (!(usersession.isDepartmentAdmin() || usersession.isSuper())) {
        elog.writeLog("[manage_course:] " + " username: "+ userId + " tried to access this page, permission denied" +" /n");        
        response.sendRedirect("calendar.jsp?message=You don't have permission to access that page");
        return;
    }
    if (dbaccess.getFlagStatus() == false) {
    	elog.writeLog("[manage_course:] " + "database connection error /n");
        response.sendRedirect("index.jsp?message=Database connection error");
        return;
    } //End page validation


    String message = request.getParameter("message");
    String successMessage = request.getParameter("successMessage");
    if (message == null || message == "null") {
        message="";
    }
    if (successMessage == null) {
        successMessage="";
    }
 
    User user = new User(dbaccess);
    Section section = new Section(dbaccess);
    ArrayList<ArrayList<String>> allCourse = new ArrayList<ArrayList<String>>();
    MyBoolean prof = new MyBoolean();
    HashMap<String, Integer> userSettings = new HashMap<String, Integer>();
    HashMap<String, Integer> meetingSettings = new HashMap<String, Integer>();
    HashMap<String, Integer> roleMask = new HashMap<String, Integer>();
    userSettings = usersession.getUserSettingsMask();
    meetingSettings = usersession.getUserMeetingSettingsMask();
    roleMask = usersession.getRoleMask();
    section.getCourse(allCourse);
    
%>

</head>
<body>
	<div id="page">
	    <jsp:include page="header.jsp"/>
	    <jsp:include page="menu.jsp"/>
	    <section>
	        <header> 
	            <!-- BREADCRUMB -->
	            <p><a href="calendar.jsp" tabindex="13">home</a> � <a href="subjects.jsp" tabindex="14">subjects</a> � <a href="manage_course.jsp" tabindex="14">manage subject</a></p>
	            <!-- PAGE NAME -->
	            <h1>Subjects List</h1>
	            <!-- WARNING MESSAGES -->
	            <div class="warningMessage"><%=message %></div>
	            <div class="successMessage"><%=successMessage %></div> 
	        </header>
	        <form>
	           <article>
	                <header>
	                    <h2>Subjects</h2>
	                    <img class="expandContent" width="9" height="6" src="images/arrowDown.svg" title="Click here to collapse/expand content"/>
	                </header>
	                <div class="content"> 
	                <div class="actionButtons" style="margin-bottom:10px;">
                    <button type="button" name="button" id="addCourse" class="button" title="Click here to add a new subject" onclick="window.location.href='create_course.jsp'">Add Subject</button>
                    </div> 
                    </div> 
	                <div class="content">                                 
		                <fieldset>
		                  <% if (usersession.isSuper() || usersession.isDepartmentAdmin()) { %>
		                  <div class="tableComponent">
								<table id="courseList" border="0" cellpadding="0" cellspacing="0">
			                       <thead>
			                          <tr>
										<th width="100" class="firstColumn" tabindex="16" title="courseid">Subject ID<span></span></th>
										<th  width="200" title="coursename">Subject Name<span></span></th>
										<th  width="65" title="Add" class="icons" align="center">Edit</th>
										<th  width="65" title="Remove" class="icons" align="center">Remove</th>
			                          </tr>
			                       </thead>
			                       <tbody>
			                        <% for(int j=0; j<allCourse.size();j++){%>
			                          <tr>
			                            <td class="row"><%= allCourse.get(j).get(0) %></td>
			                            <td ><%= allCourse.get(j).get(1) %></td>          
			                            <td  align="center"><a href="create_course.jsp?c_id=<%= allCourse.get(j).get(0) %>&c_name=<%= allCourse.get(j).get(1) %>&toEdit=1" class="modify"><img src="images/iconPlaceholder.svg" width="17" height="17" title="Add a course" alt="Edit"/></a></td>
			                            <td  align="center"><a href="create_course.jsp?c_id=<%= allCourse.get(j).get(0) %>&c_name=<%= allCourse.get(j).get(1) %>&toDel=1" class="remove"><img src="images/iconPlaceholder.svg" width="17" height="17" title="Remove course" alt="Remove"/></a></td>
			                          </tr><% } %>
			                       </tbody>
		                      </table>
		                    </div>  <% } %>
		                </fieldset>
	                </div>
	            </article>
	        </form>
	    </section>
	    <jsp:include page="footer.jsp"/>
	</div>
</body>
</html>