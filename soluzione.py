# METODI
def trova_intersezione(x1,y1,x2,y2,x3,y3,x4,y4):
    # Calcola i coefficienti delle equazioni delle rette
    m1 = (y2 - y1) / (x2 - x1) if x2 - x1 != 0 else float('inf')
    q1 = y1 - m1 * x1 if x2 - x1 != 0 else None
    m2 = (y4 - y3) / (x4 - x3) if x4 - x3 != 0 else float('inf')
    q2 = y3 - m2 * x3 if x4 - x3 != 0 else None
    # Gestisce il caso delle rette parallele
    if m1 == m2:
        return None
    # Calcola le coordinate del punto di intersezione
    if m1 == float('inf'):
        x_intersezione = x1
        y_intersezione = m2 * x1 + q2
    elif m2 == float('inf'):
        x_intersezione = x3
        y_intersezione = m1 * x3 + q1
    else:
        x_intersezione = (q2 - q1) / (m1 - m2)
        y_intersezione = m1 * x_intersezione + q1
    return x_intersezione, y_intersezione

def retta_secante_al_cerchio(m, q, centro_cerchio, raggio_cerchio):
    # Estrai le coordinate del centro del cerchio
    centro_x, centro_y = centro_cerchio
    # Calcola le coordinate del punto più vicino sulla retta al centro del cerchio
    punto_più_vicino_x = (m * centro_x + centro_y - m * q) / (m**2 + 1)
    punto_più_vicino_y = m * punto_più_vicino_x + q
    # Calcola la distanza tra il punto più vicino e il centro del cerchio
    distanza = math.sqrt((centro_x - punto_più_vicino_x)**2 + (centro_y - punto_più_vicino_y)**2)
    # La retta è secante se la distanza è minore del raggio del cerchio
    return distanza < raggio_cerchio

def punto_piu_vicino_retta_secante_al_cerchio(m, q, centro_cerchio, raggio_cerchio):
    # Estrai le coordinate del centro del cerchio
    centro_x, centro_y = centro_cerchio
    # Calcola le coordinate del punto più vicino sulla retta al centro del cerchio
    punto_più_vicino_x = (m * centro_x + centro_y - m * q) / (m**2 + 1)
    punto_più_vicino_y = m * punto_più_vicino_x + q
    return punto_più_vicino_x, punto_più_vicino_y

def plot_line(m, q, label):
    x = np.linspace(-10, 10, 100)
    y = m * x + q
    plt.plot(x, y, label=label)

def plot_circle(center, radius):
    circle = plt.Circle(center, radius, fill=False, color='r', linestyle='dashed')
    plt.gca().add_patch(circle)

def intersezione_retta_cerchio(m, q, center, radius):
    h, k = center
    # Coefficienti dell'equazione quadratica per l'intersezione
    a = 1 + m**2
    b = 2 * (m * q - m * k - h)
    c = k**2 - radius**2 + h**2 - 2 * q * k + q**2
    # Calcola le soluzioni dell'equazione quadratica
    delta = b**2 - 4 * a * c
    if delta >= 0:
        x1 = (-b + np.sqrt(delta)) / (2 * a)
        x2 = (-b - np.sqrt(delta)) / (2 * a)
        y1 = m * x1 + q
        y2 = m * x2 + q
        return [(x1, y1), (x2, y2)]
    else:
        # Nessuna intersezione reale
        return []
    
def computeMQline(x1,y1,x2,y2):
    if x2-x1 == 0:
        x2 = x2+0.01
    # Calcola i coefficienti delle equazioni delle rette
    m1 = (y2 - y1) / (x2 - x1) if x2 - x1 != 0 else float('inf')
    q1 = y1 - m1 * x1 if x2 - x1 != 0 else None
    return [m1,q1]

def coseneTheorem(P1,P2,P3):
    # angle in P1
    P1P2 = np.sqrt((P1[0]-P2[0])**2+(P1[1]-P2[1])**2)
    P1P3 = np.sqrt((P1[0]-P3[0])**2+(P1[1]-P3[1])**2)
    P2P3 = np.sqrt((P2[0]-P3[0])**2+(P2[1]-P3[1])**2)
    return np.arccos((P1P2*P1P2 + P1P3*P1P3 - P2P3*P2P3)/(2*P1P2*P1P3))

def getDistanceOnPointOnEdge(px,py,p1X,p1Y,p2X,p2Y):
    p_uX=px
    p_uY=py
    dx = p2X - p1X
    dy = p2Y - p1Y
    t = ((p_uX - p1X) * dx + (p_uY - p1Y) * dy)/(dx * dx + dy * dy)
    closestX = 0.0
    closestY = 0.0
    if t < 0:
        closestX=p1X
        closestY=p1Y
        dx = p1X - p_uX
        dy = p1Y - p_uY
    elif t > 1:
        closestX=p2X
        closestY=p2Y
        dx = p2X - p_uX
        dy = p2Y - p_uY
    else:
        closestX = p1X + t * dx
        closestY = p1Y + t * dy
        dx = closestX - p_uX
        dy = closestY - p_uY
    d = np.sqrt(dx * dx + dy * dy)
    return d

def angleBetweenTwoPoints(x_n1,x_n2,y_n1,y_n2):
    dx = (x_n2-x_n1)
    dy = (y_n2-y_n1)
    angle = np.arctan2(dy,dx)-(np.pi/2)
    return angle

def findAngleBetweenTwoEdges(x_n1,x_n2,x_n3,y_n1,y_n2,y_n3):
    angleCurrentEdge = angleBetweenTwoPoints(x_n1,x_n2,y_n1,y_n2)
    print(angleCurrentEdge*180/np.pi)
    angleNextEdge = angleBetweenTwoPoints(x_n2,x_n3,y_n2,y_n3)
    print("angleNextEdge",angleNextEdge*180/np.pi)
    angleBetweenEdges = angleCurrentEdge-angleNextEdge
    print("angleBetweenEdges",angleBetweenEdges*180/np.pi)
    return angleBetweenEdges

# DATI

dati = 4

if dati == 1:
    x_n1 = 1.0
    y_n1 = 8.0

    x_n2 = 5.0
    y_n2 = 2.0

    x_n3 = 5.2
    y_n3 = 8.0

    x_user = 2
    y_user = 6

    radius_currentEdge = 0.5  # PICCOLO
    radius_nextEdge = 1.5

    # Disegna il cerchio attorno ad n2 di e1 # Disegna il cerchio attorno ad n2 di e2
    theta = np.linspace(0, 2*np.pi, 100) # SOLO PER DEBUG QUI
    x1 = radius_currentEdge * np.cos(theta) # SOLO PER DEBUG QUI
    y1 = radius_currentEdge * np.sin(theta) # SOLO PER DEBUG QUI
    x2 = radius_nextEdge * np.cos(theta) # SOLO PER DEBUG QUI
    y2 = radius_nextEdge * np.sin(theta) # SOLO PER DEBUG QUI

elif dati == 2:
    x_n1 = 1.0
    y_n1 = 2.5

    x_n2 = 5.0
    y_n2 = 3.0

    x_n3 = 5.0
    y_n3 = 8.0

    x_user = 3
    y_user = 4

    radius_currentEdge = 1.5  # GRANDE
    radius_nextEdge = 0.5

    # Disegna il cerchio attorno ad n2 di e1 # Disegna il cerchio attorno ad n2 di e2
    theta = np.linspace(0, 2*np.pi, 100) # SOLO PER DEBUG QUI
    x1 = radius_currentEdge * np.cos(theta) # SOLO PER DEBUG QUI
    y1 = radius_currentEdge * np.sin(theta) # SOLO PER DEBUG QUI
    x2 = radius_nextEdge * np.cos(theta) # SOLO PER DEBUG QUI
    y2 = radius_nextEdge * np.sin(theta) # SOLO PER DEBUG QUI

elif dati == 3:
    x_n1 = 5.2
    y_n1 = 8.5

    x_n2 = 5.0
    y_n2 = 3.0

    x_n3 = 1.0
    y_n3 = 2.0

    x_user = 6
    y_user = 5

    radius_currentEdge = 1.5  # GRANDE
    radius_nextEdge = 0.5

    # Disegna il cerchio attorno ad n2 di e1 # Disegna il cerchio attorno ad n2 di e2
    theta = np.linspace(0, 2*np.pi, 100) # SOLO PER DEBUG QUI
    x1 = radius_currentEdge * np.cos(theta) # SOLO PER DEBUG QUI
    y1 = radius_currentEdge * np.sin(theta) # SOLO PER DEBUG QUI
    x2 = radius_nextEdge * np.cos(theta) # SOLO PER DEBUG QUI
    y2 = radius_nextEdge * np.sin(theta) # SOLO PER DEBUG QUI
elif dati == 4:
    x_n1 = 5.2
    y_n1 = 8.5

    x_n2 = 5.0
    y_n2 = 3.0

    x_n3 = 1.0
    y_n3 = 2.0

    x_user = 5.2
    y_user = 2

    radius_currentEdge = 0.5  # GRANDE
    radius_nextEdge = 1.5

    # Disegna il cerchio attorno ad n2 di e1 # Disegna il cerchio attorno ad n2 di e2
    theta = np.linspace(0, 2*np.pi, 100) # SOLO PER DEBUG QUI
    x1 = radius_currentEdge * np.cos(theta) # SOLO PER DEBUG QUI
    y1 = radius_currentEdge * np.sin(theta) # SOLO PER DEBUG QUI
    x2 = radius_nextEdge * np.cos(theta) # SOLO PER DEBUG QUI
    y2 = radius_nextEdge * np.sin(theta) # SOLO PER DEBUG QUI


angleCurrentEdge = angleBetweenTwoPoints(x_n1,x_n2,y_n1,y_n2)
angleNextEdge = angleBetweenTwoPoints(x_n2,x_n3,y_n2,y_n3)
angleBetweenEdges = angleCurrentEdge-angleNextEdge

dx1 = radius_nextEdge * np.cos(angleNextEdge)
dy2 = radius_nextEdge * np.sin(angleNextEdge)
p1x = x_n2+dx1
p1y = y_n2+dy2
p2x = x_n2-dx1
p2y = y_n2-dy2
p3x = x_n3+dx1
p3y = y_n3+dy2
p4x = x_n3-dx1
p4y = y_n3-dy2


dx3 = radius_currentEdge * np.cos(angleCurrentEdge)
dy4 = radius_currentEdge * np.sin(angleCurrentEdge)
p5x = x_n1+dx3
p5y = y_n1+dy4
p6x = x_n1-dx3
p6y = y_n1-dy4
p7x = x_n2+dx3
p7y = y_n2+dy4
p8x = x_n2-dx3
p8y = y_n2-dy4



# SOLO PER PLOT.
e1_up_x = [p1x,p3x]
e1_up_y = [p1y,p3y]
e1_down_x = [p2x,p4x]
e1_down_y = [p2y,p4y]
e2_up_x = [p5x,p7x]
e2_up_y = [p5y,p7y]
e2_down_x = [p6x,p8x]
e2_down_y = [p6y,p8y]


intersezione1 = trova_intersezione(p1x, p1y, p3x, p3y, p5x, p5y, p7x, p7y)
intersezione2 = trova_intersezione(p2x, p2y, p4x, p4y, p6x, p6y, p8x, p8y)
intersezione3 = trova_intersezione(p1x, p1y, p3x, p3y, p6x, p6y, p8x, p8y)
intersezione4 = trova_intersezione(p2x, p2y, p4x, p4y, p5x, p5y, p7x, p7y)

print(intersezione1)
print(intersezione2)
print(intersezione3)
print(intersezione4)



if radius_nextEdge < radius_currentEdge:
    line1 = computeMQline(p1x,p1y,p3x,p3y) # DIFFERENZA
    m = line1[0]
    q = line1[1]
    center = (x_n2,y_n2)
    punti_intersezione1 = intersezione_retta_cerchio(m, q, center, radius_currentEdge) # DIFFERENZA

    line1 = computeMQline(p2x,p2y,p4x,p4y) # DIFFERENZA
    m = line1[0]
    q = line1[1]
    center = (x_n2,y_n2)
    punti_intersezione2 = intersezione_retta_cerchio(m, q, center, radius_currentEdge) # DIFFERENZA
    print("radius_nextEdge < radius_currentEdge",True)
else:
    line1 = computeMQline(p5x,p5y,p7x,p7y) # DIFFERENZA
    m = line1[0]
    q = line1[1]
    center = (x_n2,y_n2)
    punti_intersezione1 = intersezione_retta_cerchio(m, q, center, radius_nextEdge) # DIFFERENZA
    
    line1 = computeMQline(p6x,p6y,p8x,p8y) # DIFFERENZA
    m = line1[0]
    q = line1[1]
    center = (x_n2,y_n2)
    punti_intersezione2 = intersezione_retta_cerchio(m, q, center, radius_nextEdge) # DIFFERENZA
    print("radius_nextEdge < radius_currentEdge",False)
print(punti_intersezione1)
print(punti_intersezione2)



angleCurrentEdgeUser = angleBetweenTwoPoints(x_user,x_n2,y_user,y_n2)
"""angleNextEdge = angleBetweenTwoPoints(x_n2,x_n3,y_n2,y_n3)
angleBetweenEdgeAndUser = angleCurrentEdgeUser-angleNextEdge"""

cateto1 = min(radius_currentEdge,radius_nextEdge)
distance = np.sqrt((x_user-x_n2)*(x_user-x_n2)+(y_user-y_n2)*(y_user-y_n2))
alpha = np.arcsin(cateto1/abs(distance))
if alpha==None:
    alpha = 90.0*np.pi/180

a1 = angleCurrentEdgeUser + alpha
dxPN1 = distance * np.sin(a1)
dyPN1 = distance * np.cos(a1)
x_PN1 = x_user - dxPN1
y_PN1 = y_user + dyPN1
a2 = angleCurrentEdgeUser - alpha
dxPN2 = distance * np.sin(a2)
dyPN2 = distance * np.cos(a2)
x_PN2 = x_user - dxPN2
y_PN2 = y_user + dyPN2

"""print("alpha",alpha*180/np.pi)
print("angleBetweenEdgeAndUser",angleBetweenEdgeAndUser*180/np.pi)
print("angleCurrentEdgeUser",angleCurrentEdgeUser*180/np.pi)
print("angleNextEdge",angleNextEdge*180/np.pi)
print("a1",a1*180/np.pi)
print("a2",a2*180/np.pi)
print("dxPN1",dxPN1)
print("dxPN2",dxPN2)"""



points = []

PN1 = (x_PN1,y_PN1)
distancePN1_edge1 = getDistanceOnPointOnEdge(PN1[0],PN1[1],x_n1,y_n1,x_n2,y_n2)
distancePN1_edge2 = getDistanceOnPointOnEdge(PN1[0],PN1[1],x_n2,y_n2,x_n3,y_n3)
print(distancePN1_edge1,distancePN1_edge2)
if (distancePN1_edge1-radius_currentEdge)<0.15 and (distancePN1_edge2-radius_nextEdge)<0.15:
    points.append(PN1)
else:
    print("scarto PN1")

PN2 = (x_PN2,y_PN2)
distancePN2_edge1 = getDistanceOnPointOnEdge(PN2[0],PN2[1],x_n1,y_n1,x_n2,y_n2)
distancePN2_edge2 = getDistanceOnPointOnEdge(PN2[0],PN2[1],x_n2,y_n2,x_n3,y_n3)
print(distancePN2_edge1,distancePN2_edge2)
if (distancePN2_edge1-radius_currentEdge)<0.15 and (distancePN2_edge2-radius_nextEdge)<0.15:
    points.append(PN2)
else:
    print("scarto PN2")


pointsIntersection=[]
pointsIntersection.append(intersezione1)
pointsIntersection.append(intersezione2)
pointsIntersection.append(intersezione3)
pointsIntersection.append(intersezione4)


print((angleBetweenEdges)*180/np.pi)
if 180-abs(angleBetweenEdges)*180/np.pi < 90:
    for i in pointsIntersection:
        distancei_edge1 = getDistanceOnPointOnEdge(i[0],i[1],x_n1,y_n1,x_n2,y_n2)
        distancei_edge2 = getDistanceOnPointOnEdge(i[0],i[1],x_n2,y_n2,x_n3,y_n3)
        print(distancei_edge1,distancei_edge2)
        if (distancei_edge1-radius_currentEdge)<0.15 and (distancei_edge2-radius_nextEdge)<0.15:
            points.append(i)
        else:
            print("scarto i",i)
else:
    for i in punti_intersezione1:
        distancei_edge1 = getDistanceOnPointOnEdge(i[0],i[1],x_n1,y_n1,x_n2,y_n2)
        distancei_edge2 = getDistanceOnPointOnEdge(i[0],i[1],x_n2,y_n2,x_n3,y_n3)
        print(distancei_edge1,distancei_edge2)
        if (distancei_edge1-radius_currentEdge)<0.15 and (distancei_edge2-radius_nextEdge)<0.15:
            points.append(i)
        else:
            print("scarto i",i)
    for i in punti_intersezione2:
        distancei_edge1 = getDistanceOnPointOnEdge(i[0],i[1],x_n1,y_n1,x_n2,y_n2)
        distancei_edge2 = getDistanceOnPointOnEdge(i[0],i[1],x_n2,y_n2,x_n3,y_n3)
        print(distancei_edge1,distancei_edge2)
        if (distancei_edge1-radius_currentEdge)<0.15 and (distancei_edge2-radius_nextEdge)<0.15:
            points.append(i)
        else:
            print("scarto i",i)

p_user=(x_user,y_user)

maxAngle = 0
p1scelto = []
p2scelto = []
for p1 in points:
    for p2 in points:
        kAngle = coseneTheorem(p_user,p1,p2)*180/np.pi
        if p1 != p2 and kAngle>maxAngle:
            maxAngle = kAngle
            p1scelto=p1
            p2scelto=p2
                    
print(maxAngle,p1scelto,p2scelto)






# plt.plot(p_x,p_y)
plt.plot(x1+x_n2, y1+y_n2)
plt.plot(x1+x_n1, y1+y_n1)
plt.plot(x2+x_n2, y2+y_n2, color="red")
plt.plot(x2+x_n3, y2+y_n3)
plt.scatter(p1x,p1y, color="green",s=40)
plt.scatter(p2x,p2y, color="red",s=40)
plt.scatter(p3x,p3y, color="green",s=40)
plt.scatter(p4x,p4y, color="red",s=40)
plt.scatter(p5x,p5y, color="green",s=40)
plt.scatter(p6x,p6y, color="red",s=40)
plt.scatter(p7x,p7y, color="green",s=40)
plt.scatter(p8x,p8y, color="red",s=40)
plt.plot(e1_down_x,e1_down_y,color="red")
plt.plot(e1_up_x,e1_up_y)
plt.plot(e2_down_x,e2_down_y,color="green")
plt.plot(e2_up_x,e2_up_y)

plt.scatter(x_PN1,y_PN1,color="orange")
plt.scatter(x_PN2,y_PN2,color="orange")

plt.scatter(x_user,y_user,color="black",s=40)


if 180-abs(angleBetweenEdges)*180/np.pi < 90:
    # APPROCCIO NON FUNZIONANTE ALLA PERFEZIONE
    plt.scatter(intersezione1[0],intersezione1[1],color="blue",s=40)
    plt.scatter(intersezione2[0],intersezione2[1],color="blue",s=40)
    plt.scatter(intersezione3[0],intersezione3[1],color="blue",s=40)
    plt.scatter(intersezione4[0],intersezione4[1],color="blue",s=40)
else:
    # NUOVO APPROCCIO
    for i in punti_intersezione1:
        plt.scatter(i[0],i[1], color="violet")
    for i in punti_intersezione2:
        plt.scatter(i[0],i[1], color="violet")
"""
if intersezione1 != None:
    plt.scatter(intersezione1[0],intersezione1[1],color="blue",s=40)
if intersezione2 != None:
    plt.scatter(intersezione2[0],intersezione2[1],color="blue",s=40)
if intersezione3 != None:
    plt.scatter(intersezione3[0],intersezione3[1],color="blue",s=40)
if intersezione4 != None:
    plt.scatter(intersezione4[0],intersezione4[1],color="blue",s=40)

if len(punti_intersezione1) != 0:
    for i in punti_intersezione1:
        plt.scatter(i[0],i[1], color="violet")
if len(punti_intersezione2) != 0:
    for i in punti_intersezione2:
        plt.scatter(i[0],i[1], color="violet")
"""        
plt.scatter(p1scelto[0],p1scelto[1],color="cyan")
plt.scatter(p2scelto[0],p2scelto[1],color="cyan")


plt.axis('equal')
plt.show()
