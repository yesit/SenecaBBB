<%@page import="db.DBConnection"%>
<%@ page import="java.util.*, javax.mail.*, javax.mail.internet.*" %> 
<%@page import="sql.Admin"%>
<%@page import="sql.User"%>
<%@page import="config.Config"%>
<%@page import="helper.*"%>
<jsp:useBean id="dbaccess" class="db.DBAccess" scope="session" />
<jsp:useBean id="usersession" class="helper.UserSession" scope="session" />
<%
	//Start page validation
	String userId = usersession.getUserId();
    GetExceptionLog elog = new GetExceptionLog();
	String message = request.getParameter("message");
	String successMessage = request.getParameter("successMessage");
	if (message == null || message == "null") {
	    message="";
	}
	if (successMessage == null) {
	    successMessage="";
	}
	HashMap<String, Integer> roleMask = usersession.getRoleMask();
	if (userId.equals("")) {
		session.setAttribute("redirecturl", request.getRequestURI()+(request.getQueryString()!=null?"?"+request.getQueryString():""));
	    response.sendRedirect("index.jsp?message=Please log in");
	    return;
	}
	if(!(usersession.isSuper()||usersession.getUserLevel().equals("employee")||roleMask.get("guestAccountCreation") == 0)) {
	    elog.writeLog("[email:] " + " username: "+ userId + " tried to access this page, permission denied" +" /n");       
		response.sendRedirect("calendar.jsp?message=You do not have permission to access that page");
	    return;
	}
	if (dbaccess.getFlagStatus() == false) {
		elog.writeLog("[email:] " + "database connection error /n");
		response.sendRedirect("index.jsp?message=Database connection error");
	    return;
	}//End page validation

	Email sendToGuest = new Email();
    String to = session.getAttribute("email").toString();
    String subject = "SenecaBBB Guest Account Activation"; 
    String key = session.getAttribute("key").toString();
    String bu_id = session.getAttribute("bu_id").toString();  
    String link = Config.getProperty("domain")+"SenecaBBB/guest_setup.jsp?&key=" + key + "&user=" + bu_id;
    String messageText = "<p>Dear Guest User:</p><p>You are invited to join an event in our web conferencing system. A guest account is created for you.</p><p> Your user name is: <strong>" 
                         + bu_id + "</strong></p><p> Please visit the following link to activate your account:</p>"+ link; 
	if(sendToGuest.send(to, subject, messageText)){
        successMessage="Email sent";
	    response.sendRedirect("calendar.jsp?successMessage="+ successMessage);
	}else{
	    message="Fail to send email";
	    response.sendRedirect("calendar.jsp?message="+ message);
	}
%>