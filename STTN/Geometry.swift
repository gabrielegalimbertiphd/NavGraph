import Foundation

class Geometry {
    
    func trova_intersezione(_ x1:Float, _ y1:Float, _ x2:Float, _ y2:Float, _ x3:Float, _ y3:Float, _ x4:Float, _ y4:Float)->(Float,Float)?{
        // Calcola i coefficienti delle equazioni delle rette
        
        var m1: Float
        var q1: Float?

        if x2 - x1 != 0 {
            m1 = (y2 - y1) / (x2 - x1)
            q1 = y1 - m1 * x1
        } else {
            m1 = Float.infinity
            q1 = nil
        }

        var m2: Float
        var q2: Float?

        if x4 - x3 != 0 {
            m2 = (y4 - y3) / (x4 - x3)
            q2 = y3 - m2 * x3
        } else {
            m2 = Float.infinity
            q2 = nil
        }

        // Gestisce il caso delle rette parallele
        if m1 == m2 {
            // Handle the case of parallel lines
            // You may choose an appropriate way to represent this case, such as returning nil or using an optional
            return nil
        }

        // Calcola le coordinate del punto di intersezione
        var x_intersezione: Float
        var y_intersezione: Float

        if m1 == Float.infinity {
            x_intersezione = x1
            y_intersezione = m2 * x1 + q2!
        } else if m2 == Float.infinity {
            x_intersezione = x3
            y_intersezione = m1 * x3 + q1!
        } else {
            x_intersezione = (q2! - q1!) / (m1 - m2)
            y_intersezione = m1 * x_intersezione + q1!
        }

        return (x_intersezione, y_intersezione)

    }
    
    func retta_secante_al_cerchio(m: Float, q: Float, centro_x: Float, centro_y: Float, raggio_cerchio: Float) -> Bool {
        // Calcola le coordinate del punto più vicino sulla retta al centro del cerchio
        let punto_più_vicino_x = (m * centro_x + centro_y - m * q) / (m * m + 1)
        let punto_più_vicino_y = m * punto_più_vicino_x + q
        // Calcola la distanza tra il punto più vicino e il centro del cerchio
        let distanza = sqrt(pow((centro_x - punto_più_vicino_x), 2) + pow((centro_y - punto_più_vicino_y), 2))
        // La retta è secante se la distanza è minore del raggio del cerchio
        return distanza < raggio_cerchio
    }

    func punto_piu_vicino_retta_secante_al_cerchio(m: Float, q: Float, centerCircle: (Float, Float), radiusCircle: Float) -> (Float, Float) {
        // Extract coordinates of the center of the circle
        let (centro_x, centro_y) = centerCircle
        // Calculate coordinates of the closest point on the line to the center of the circle
        let punto_piu_vicino_x = (m * centro_x + centro_y - m * q) / (pow(m, 2) + 1)
        let punto_piu_vicino_y = m * punto_piu_vicino_x + q
        
        return (punto_piu_vicino_x, punto_piu_vicino_y)
    }

    func intersezione_retta_cerchio(m: Float, q: Float, center: (Float, Float), radius: Float) -> [(Float, Float)] {
        let (h, k) = center
        
        // Coefficienti dell'equazione quadratica per l'intersezione
        let a = 1 + pow(m, 2)
        let b = 2 * (m * q - m * k - h)
        let c = pow(k, 2) - pow(radius, 2) + pow(h, 2) - 2 * q * k + pow(q, 2)
        
        // Calcola le soluzioni dell'equazione quadratica
        let delta = pow(b, 2) - 4 * a * c
        
        if delta >= 0 {
            let x1 = (-b + sqrt(delta)) / (2 * a)
            let x2 = (-b - sqrt(delta)) / (2 * a)
            let y1 = m * x1 + q
            let y2 = m * x2 + q
            return [(x1, y1), (x2, y2)]
        } else {
            // Nessuna intersezione reale
            return []
        }
    }
        
    func computeMQline(x1: Float, y1: Float, x2: Float, y2: Float) -> [Float?] {
        var x2Adjusted = x2
        if x2 - x1 == 0 {
            x2Adjusted = x2 + 0.01
        }
        // Calcola i coefficienti delle equazioni delle rette
        let m1: Float = (y2 - y1) / (x2Adjusted - x1)
        let q1: Float? = (x2Adjusted - x1 != 0) ? (y1 - m1 * x1) : nil
        return [m1, q1]
    }

    func cosineTheorem(P1: (Float,Float), P2: (Float,Float), P3: (Float,Float)) -> Float {
        // Separate x and y coordinates for each point
        let x1 = P1.0, y1 = P1.1
        let x2 = P2.0, y2 = P2.1
        let x3 = P3.0, y3 = P3.1

        // Calculate distances between points
        let P1P2 = sqrt(pow((x1 - x2), 2) + pow((y1 - y2), 2))
        let P1P3 = sqrt(pow((x1 - x3), 2) + pow((y1 - y3), 2))
        let P2P3 = sqrt(pow((x2 - x3), 2) + pow((y2 - y3), 2))
        
        // Calculate the angle using the cosine theorem
        return acos((pow(P1P2, 2) + pow(P1P3, 2) - pow(P2P3, 2)) / (2 * P1P2 * P1P3))
    }

    func getDistanceOnPointOnEdge(position: (px:Float,py:Float), p1X: Float, p1Y: Float, p2X: Float, p2Y: Float) -> Float {
        
        let p_uX:Float=position.px
        let p_uY:Float=position.py
        
        var dx : Float = p2X - p1X
        var dy : Float = p2Y - p1Y
        
        let t : Float = ((p_uX - p1X) * dx + (p_uY - p1Y) * dy)/(dx * dx + dy * dy)
        var closestX : Float = 0.0
        var closestY : Float = 0.0
        
        if (t < 0) { // See if this represents one of the segment's end points or a point in the middle. // DIVIDERE IN getClosestPoint e getClosestPointDistance.
            closestX=p1X
            closestY=p1Y
            dx = p1X - p_uX
            dy = p1Y - p_uY
        } else if (t > 1) {
            closestX=p2X
            closestY=p2Y
            dx = p2X - p_uX
            dy = p2Y - p_uY
        } else {
            closestX = p1X + t * dx
            closestY = p1Y + t * dy      // SISTEMARE PERCHÈ RITORNO UNA DISTANZA E NON UN PUNTO … SISTEMA SLIDE 25
            dx = closestX - p_uX
            dy = closestY - p_uY
        }
        let d = sqrt(dx * dx + dy * dy)
        
        return d
    }

    func angleBetweenTwoPoints(x_n1: Float, x_n2: Float, y_n1: Float, y_n2: Float) -> Float {
        var dx = x_n2 - x_n1
        print(dx)
        var dy = y_n2 - y_n1
        print(dy)
        return atan2(dy, dx) - (Float.pi / 2)
    }

    func findAngleBetweenTwoEdges(x_n1: Float, x_n2: Float, x_n3: Float, y_n1: Float, y_n2: Float, y_n3: Float) -> Float {
        let angleCurrentEdge = angleBetweenTwoPoints(x_n1: x_n1, x_n2: x_n2, y_n1: y_n1, y_n2: y_n2)
        let angleNextEdge = angleBetweenTwoPoints(x_n1: x_n2, x_n2: x_n3, y_n1: y_n2, y_n2: y_n3)
        let angleBetweenEdges = angleCurrentEdge - angleNextEdge
        return angleBetweenEdges
    }
    
    
}

