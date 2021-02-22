//
//  UIKitDurationTests.swift
//  RevealSpringAnimationTests
//
//  Created by Pan Yusheng on 2021/2/21.
//

import XCTest
@testable import RevealSpringAnimation

extension SpringCurve {
    // The time t such that |c2| * exp(a * t) = 0.001
    var estimatedDuration: Double {
        assert(0 < dampingRatio && dampingRatio < 1)

        let v0 = initialVelocity
        let zeta = dampingRatio

        let a = -omega * zeta
        let b = omega * sqrt(1 - zeta * zeta)
        let c2 = (v0 + a) / b

        // c2 should not equal to 0 if omega is found by OmegaSolver, since omega satisfies |c2| * exp(a * t) = 0.001
        return log(0.001 / abs(c2)) / a
    }
}

class UIKitDurationTests: XCTestCase {
    func testSolution(parameter: UIKitSpring) {
        let spring = SpringCurve(parameter)
        let systemSpring = SpringCurve(SystemUIKitAnimationConverter.convert(uiValue: parameter))

        XCTAssertEqual(spring.estimatedDuration, parameter.duration, accuracy: 1e-8)
        XCTAssertEqual(spring.omega, systemSpring.omega, accuracy: 1e-4)
    }

    func testZeroVelocity() {
        testSolution(parameter: UIKitSpring(duration: 1, dampingRatio: 0.8, initialVelocity: 0))
    }

    func testALot() {
        let durations = [1.0, 3.0]
        let dampingRatios = stride(from: 0.1, to: 1.0, by: 0.1)
        let v0s = stride(from: -10.0, to: 0, by: 0.2)

        for d in durations {
            for zeta in dampingRatios {
                for v0 in v0s {
                    testSolution(parameter: UIKitSpring(duration: d, dampingRatio: zeta, initialVelocity: v0))
                }
            }
        }
    }

    // When initial velocity is positive, system API has chaotic behavior, iOS 14.4
    func testChaos() {
        let data: [(Int, Double)] = [
            (210, 4.563081181386087),
            (211, 4.562848965635916),
            (212, 4.562616670674333),
            (213, 4.562384288525174),
            (214, 29.7174775875498),
            (215, 0.21238673121318224),
            (216, 0.03714229689742772),
            (217, 4.5614538387698085),
            (218, 4.561221235472331),
            (219, 0.21632772288215876),
            (220, 14.612212198062293),
            (221, 0.056038597707982196),
            (222, 0.21928154114275633),
            (223, 0.22026821174440991),
            (224, 0.22125317924244423),
            (225, 0.2222380314940772),
            (226, 0.22886274306886692),
            (227, 0.22420723312191074),
            (228, 0.22519344386142331),
            (229, 0.22617838918213107),
            (230, 0.22716328533973595),
            (231, 4.558188096287089),
            (232, 4.55795417620894),
            (233, 1.3487210704577806),
            (234, 78.16563507082961),
            (235, 4.557252116619635),
            (236, 4.557017911183073),
            (237, 4.55678364809281),
            (238, 4.556549293847785),
            (239, 4.55631485952561),
            (240, 4.556080345142903),
            (241, 4.555845750711907),
            (242, 4.55561107609808),
            (243, 4.5553763212003435),
            (244, 4.555141485944363),
            (245, 4.5549065702922515),
            (246, 4.554671493647424),
            (247, 4.554436493396288),
            (248, 4.554201340364016),
            (249, 4.553965989201964),
            (250, 4.553730784077176),
            (251, 4.553495311646087),
            (252, 4.553259904756891),
            (253, 31.359200083698582),
            (254, 0.25079307331164546),
            (255, 0.2517772943916617),
            (256, 6.972113790475847),
            (257, 0.4299680051290053),
            (258, 0.13398104574964204),
            (259, 0.25571327074827294),
            (260, 0.2566978588520846),
            (261, 4.551136937345388),
            (262, 0.2586665392763341),
            (263, 20.81966718190041),
            (264, 4.550427713635742),
            (265, 0.26161852911692174),
            (266, 4.048117816144064),
            (267, 0.26358638286936564),
            (268, 0.2645683013152148),
            (269, 0.26555412624574115),
            (270, 4.549007373764477),
            (271, 4.5487702367533265),
            (272, 4.548533237402283),
            (273, 4.548296045931737),
            (274, 4.5480587723296235),
            (275, 4.547821415091565),
            (276, 4.547583978249588),
            (277, 12.059471247441625),
            (278, 0.27440589375281726),
            (279, 0.2753893530685444),
            (280, 0.27637166641150285),
            (281, 0.2773581593168305),
            (282, 2.307634130788006),
            (283, 0.2793248468786106),
            (284, 0.2803085983878013),
            (285, 4.545443143168735),
            (286, 4.545205055725873),
            (287, 4.5449667078160845),
            (288, 5.215848307216217),
            (289, 4.543650720554705),
            (290, 2.5086144651337046),
            (291, 4.54401246742506),
            (292, 4.543773721692829),
            (293, 0.2891564966574432),
            (294, 4.543291281461728),
            (295, 5.329992844952693),
            (296, 0.2921075672406757),
            (297, 0.29307395005651127),
            (298, 0.2940693472210874),
            (299, 0.29505665673534776),
        ]

        for point in data {
            let v0 = Double(point.0) / 10000.0
            let omega = point.1

            let parameter = UIKitSpring(duration: 10, dampingRatio: 0.1, initialVelocity: v0)
            let systemSpring = SpringCurve(SystemUIKitAnimationConverter.convert(uiValue: parameter))

            XCTAssertEqual(systemSpring.omega, omega, accuracy: 1e-8)
        }

    }
}
