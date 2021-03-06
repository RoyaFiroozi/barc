#!/usr/bin/env python

import math

def lla2flat(lla, llo, psio, href):
    '''
    lla  -- array of geodetic coordinates 
            (latitude, longitude, and altitude), 
            in [degrees, degrees, meters]. 
 
            Latitude and longitude values can be any value. 
            However, latitude values of +90 and -90 may return 
            unexpected values because of singularity at the poles.
 
    llo  -- Reference location, in degrees, of latitude and 
            longitude, for the origin of the estimation and 
            the origin of the flat Earth coordinate system.
 
    psio -- Angular direction of flat Earth x-axis 
            (degrees clockwise from north), which is the angle 
            in degrees used for converting flat Earth x and y 
            coordinates to the North and East coordinates.
 
    href -- Reference height from the surface of the Earth to 
            the flat Earth frame with regard to the flat Earth 
            frame, in meters.
 
    usage: print(lla2flat((0.1, 44.95, 1000.0), (0.0, 45.0), 5.0, -100.0))
 
    '''
 
    R = 6378137.0  # Equator radius in meters
    f = 0.00335281066474748071  # 1/298.257223563, inverse flattening

    Lat_p = lla[0] * math.pi / 180.0  # from degrees to radians
    Lon_p = lla[1] * math.pi / 180.0  # from degrees to radians
    Alt_p = lla[2]  # meters
 
    # Reference location (lat, lon), from degrees to radians
    Lat_o = llo[0] * math.pi / 180.0
    Lon_o = llo[1] * math.pi / 180.0
     
    psio = psio * math.pi / 180.0  # from degrees to radians
 
    dLat = Lat_p - Lat_o
    dLon = Lon_p - Lon_o
 
    ff = (2.0 * f) - (f ** 2)  # Can be precomputed
 
    sinLat = math.sin(Lat_o)
 
    # Radius of curvature in the prime vertical
    Rn = R / math.sqrt(1 - (ff * (sinLat ** 2)))
 
    # Radius of curvature in the meridian
    Rm = Rn * ((1 - ff) / (1 - (ff * (sinLat ** 2))))
 
    dNorth = (dLat) / math.atan2(1, Rm)
    dEast = (dLon) / math.atan2(1, (Rn * math.cos(Lat_o)))
 
    # Rotate matrice clockwise
    Xp = (dNorth * math.cos(psio)) + (dEast * math.sin(psio))
    Yp = (-dNorth * math.sin(psio)) + (dEast * math.cos(psio))
    Zp = -Alt_p - href
    
    # change to coordinate system with z axis pointing away from the center of earth
    return Xp, -Yp, -Zp

def flat2lla(p, llo, psio, href):
    '''
    p    -- array of flat earth coordinates 
            (x, y and z), 
            in [meters, meters, meters]. 
 
    llo  -- Reference location, in degrees, of latitude and 
            longitude, for the origin of the estimation and 
            the origin of the flat Earth coordinate system.
 
    psio -- Angular direction of flat Earth x-axis 
            (degrees clockwise from north), which is the angle 
            in degrees used for converting flat Earth x and y 
            coordinates to the North and East coordinates.
 
    href -- Reference height from the surface of the Earth to 
            the flat Earth frame with regard to the flat Earth 
            frame, in meters.
 
    usage: print(flat2lla((4731.0, 4511.0, 120.0), (0.0, 45.0), 5.0, -100.0))
 
    '''


    R = 6378137.0  # Equator radius in meters
    f = 0.00335281066474748071  # 1/298.257223563, inverse flattening

    # change to coordinate system with z axis pointing to the center of earth
    X = p[0]
    Y = -p[1]
    Z = -p[2]

    # Reference location (lat, lon), from degrees to radians
    Lat_o = llo[0] * math.pi / 180.0
    Lon_o = llo[1] * math.pi / 180.0

    psio = psio * math.pi / 180.0  # from degrees to radians

    dNorth = math.cos(psio)*X - math.sin(psio)*Y
    dEast  = math.sin(psio)*X + math.cos(psio)*Y

    ff = (2.0 * f) - (f ** 2)  # Can be precomputed
 
    sinLat = math.sin(Lat_o)
 
    # Radius of curvature in the prime vertical
    Rn = R / math.sqrt(1 - (ff * (sinLat ** 2)))
 
    # Radius of curvature in the meridian
    Rm = Rn * ((1 - ff) / (1 - (ff * (sinLat ** 2))))

    dLat = (dNorth) * math.atan2(1, Rm);
    dLon = (dEast)*math.atan2(1, Rn * math.cos(Lat_o))

    lla0 = dLat * 180.0 / math.pi + llo[0]
    lla1 = dLon * 180.0 / math.pi + llo[1]
    lla2 = -Z - href

    return lla0, lla1, lla2